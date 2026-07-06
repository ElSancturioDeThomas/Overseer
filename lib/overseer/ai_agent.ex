defmodule Overseer.AIAgent do
  @moduledoc """
  The Overseer assistant agent.

  Owns the system prompt and the tool catalog, and runs the tool-use loop: it
  sends the conversation to the LLM, and whenever the model asks to use a tool
  it runs the matching function, feeds the result back, and asks again, until
  the model produces a final text answer.

  The transport (talking to Bedrock) lives in `Overseer.LLM`. This module owns *what*
  to say and *which* tools exist. Each tool is a thin wrapper over an existing
  context function.
  """

  alias Overseer.Acra
  alias Overseer.Management.AssetManagement
  alias Overseer.Management.EntityManagement
  alias Overseer.HydraDB
  alias Overseer.LLM
  alias Overseer.Management.PeopleManagement

  # Stop runaway tool loops after this many round-trips with the model.
  @max_turns 5

  @doc """
  Runs the agent over a conversation history and returns the final reply.

  `history` is a list of `%{role: :user | :assistant, content: binary}`, the
  same shape the LiveView keeps for display.

  Returns `{:ok, text}` or `{:error, reason}`.
  """
  def run(history) when is_list(history) do
    history
    |> Enum.map(&to_api_message/1)
    |> loop(@max_turns)
  end

  defp to_api_message(%{role: role, content: content}) do
    %{role: to_string(role), content: content}
  end

  # --- The tool-use loop -------------------------------------------------

  defp loop(_messages, 0), do: {:error, :max_turns_exceeded}

  defp loop(messages, turns_left) do
    case LLM.chat(messages, system: system_prompt(), tools: tools()) do
      # The model wants to use one or more tools before answering.
      {:ok, %{"stop_reason" => "tool_use", "content" => content}} ->
        tool_results = Enum.flat_map(content, &run_block/1)

        messages =
          messages ++
            [
              # Echo the model's tool-use turn back verbatim...
              %{role: "assistant", content: content},
              # ...then hand it the results so it can continue.
              %{role: "user", content: tool_results}
            ]

        loop(messages, turns_left - 1)

      # A normal, final text answer.
      {:ok, %{"content" => content}} ->
        {:ok, extract_text(content)}

      {:ok, other} ->
        {:error, {:unexpected_response, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Turn each tool_use block into a tool_result block; ignore everything else.
  defp run_block(%{"type" => "tool_use", "id" => id, "name" => name, "input" => input}) do
    [%{type: "tool_result", tool_use_id: id, content: run_tool(name, input)}]
  end

  defp run_block(_block), do: []

  defp extract_text(content) do
    content
    |> Enum.filter(&(&1["type"] == "text"))
    |> Enum.map_join("\n", & &1["text"])
  end

  # --- Tool implementations: each wraps an existing context function -----

  defp run_tool("list_entities", _input) do
    EntityManagement.list_entities()
    |> Enum.map(fn e ->
      %{
        id: e.id,
        uen: e.uen,
        status: e.status,
        type: e.type,
        industry: e.industry,
        address: e.address,
        suburb: e.suburb,
        contact_number: e.contact_number,
        incorporation_date: iso(e.incorporation_date)
      }
    end)
    |> Jason.encode!()
  end

  defp run_tool("list_people", _input) do
    PeopleManagement.list_people()
    |> Enum.map(fn p ->
      %{
        id: p.id,
        name: p.name,
        designation: p.designation,
        role: p.role,
        id_number: p.id_number,
        dob: iso(p.dob),
        entity_uen: p.entity && p.entity.uen
      }
    end)
    |> Jason.encode!()
  end

  defp run_tool("list_assets", _input) do
    AssetManagement.list_assets()
    |> Enum.map(fn a ->
      %{
        id: a.id,
        name: a.name,
        code: a.code,
        type: a.type,
        value: a.value && to_string(a.value),
        acquisition_date: iso(a.acquisition_date),
        entity_uen: a.entity && a.entity.uen
      }
    end)
    |> Jason.encode!()
  end

  defp run_tool("lookup_acra_profile", %{"uen" => uen}) do
    case Acra.get_business_profile(uen) do
      {:ok, profile} -> profile |> Map.from_struct() |> Jason.encode!()
      {:error, _reason} -> Jason.encode!(%{error: "Could not fetch ACRA profile for #{uen}"})
    end
  end

  defp run_tool("search_memory", %{"query" => query}) do
    case HydraDB.query(%{tenant_id: "default-tenant", query: query, type: "all", max_results: 5}) do
      {:ok, data} ->
        data
        |> Map.get("chunks", [])
        |> Enum.map(fn chunk ->
          %{
            content: chunk["chunk_content"],
            source: chunk["source_title"],
            score: chunk["relevancy_score"]
          }
        end)
        |> Jason.encode!()

      {:error, reason} ->
        Jason.encode!(%{error: "Memory search failed: #{inspect(reason)}"})
    end
  end

  defp run_tool("create_person", %{"entity_uen" => uen} = input) do
    with_entity(uen, fn entity ->
      attrs = %{
        "name" => input["name"],
        "dob" => input["date_of_birth"],
        "id_number" => input["id_number"],
        "designation" => input["designation"],
        "role" => input["role"],
        "residential_address" => input["residential_address"],
        "appointment_date" => input["appointment_date"],
        "resignation_date" => input["resignation_date"],
        "entity_id" => entity.id
      }

      created("person", PeopleManagement.create_person(attrs))
    end)
  end

  defp run_tool("create_asset", %{"entity_uen" => uen} = input) do
    with_entity(uen, fn entity ->
      attrs = %{
        "name" => input["name"],
        "code" => input["code"],
        "type" => input["type"],
        "value" => input["value"],
        "acquisition_date" => input["acquisition_date"],
        "entity_id" => entity.id
      }

      created("asset", AssetManagement.create_asset(attrs))
    end)
  end

  defp run_tool(name, _input) do
    Jason.encode!(%{error: "Unknown tool: #{name}"})
  end

  # Resolve the UEN to an entity, then run `fun`. Returns a JSON error string
  # if no entity matches, so the model can tell the user.
  defp with_entity(uen, fun) do
    case EntityManagement.get_entity_by_uen(uen) do
      nil -> Jason.encode!(%{error: "No entity found with UEN #{uen}; nothing was created."})
      entity -> fun.(entity)
    end
  end

  # Turn a create result into a JSON message for the model: the new id on
  # success, or the changeset's validation errors on failure.
  defp created(kind, {:ok, record}) do
    Jason.encode!(%{success: true, kind: kind, id: record.id, message: "#{kind} created."})
  end

  defp created(kind, {:error, changeset}) do
    Jason.encode!(%{success: false, kind: kind, errors: changeset_errors(changeset)})
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp iso(nil), do: nil
  defp iso(%Date{} = date), do: Date.to_iso8601(date)

  # --- Configuration: the system prompt and the tool catalog ------------

  defp system_prompt do
    """
    You are the assistant for Overseer, an application for managing a registry of
    Singapore corporate entities and the people associated with them (directors,
    officers, and shareholders).

    Answer questions about the entities, people, and assets stored in the system,
    and look up official company information from ACRA when asked. You can also recall
    earlier conversations and stored notes with the search_memory tool; use it
    when the user refers to something discussed before. Always use the provided
    tools to fetch real data rather than guessing. If a tool returns nothing, say
    so plainly. Be concise and factual, and never invent UENs, names, or dates.

    You can create new people and assets with the create_person and create_asset
    tools. Both are linked to an entity by its UEN. Only create a record when the
    user clearly asks. Make sure you have every required field first (a person
    needs name, date of birth, ID number, and the entity UEN); if anything is
    missing, ask the user rather than inventing it. After a successful creation,
    confirm exactly what you created.
    """
  end

  defp tools do
    [
      %{
        name: "list_entities",
        description:
          "List all entities (companies) in the Overseer registry, with their UEN, status, type, and incorporation date.",
        input_schema: %{type: "object", properties: %{}, required: []}
      },
      %{
        name: "list_people",
        description:
          "List all people in the registry (directors, officers, shareholders), with name, designation, ID number, date of birth, and the UEN of the entity they belong to.",
        input_schema: %{type: "object", properties: %{}, required: []}
      },
      %{
        name: "list_assets",
        description:
          "List all assets (holdings) in the registry, with their name, type, value, acquisition date, and the UEN of the entity that owns them.",
        input_schema: %{type: "object", properties: %{}, required: []}
      },
      %{
        name: "lookup_acra_profile",
        description:
          "Look up an official ACRA business profile for a Singapore entity by its UEN. Use for authoritative company details not stored locally.",
        input_schema: %{
          type: "object",
          properties: %{
            uen: %{type: "string", description: "The Unique Entity Number, e.g. \"16888888A\"."}
          },
          required: ["uen"]
        }
      },
      %{
        name: "search_memory",
        description:
          "Search stored memories and knowledge from previous conversations and ingested context. Use this to recall what was discussed earlier or to find relevant background before answering.",
        input_schema: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description: "What to search for: a topic, question, or keywords."
            }
          },
          required: ["query"]
        }
      },
      %{
        name: "create_person",
        description:
          "Create a new person (director, officer, or shareholder) linked to an entity. Only call this when the user clearly wants to add someone, and after you have the required fields.",
        input_schema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Full name."},
            date_of_birth: %{type: "string", description: "Date of birth as YYYY-MM-DD."},
            id_number: %{type: "string", description: "Identity document number."},
            entity_uen: %{type: "string", description: "UEN of the entity this person belongs to."},
            designation: %{type: "string", description: "Designation, e.g. Director or Secretary."},
            role: %{type: "string", description: "The person's role."},
            residential_address: %{type: "string"},
            appointment_date: %{type: "string", description: "YYYY-MM-DD."},
            resignation_date: %{type: "string", description: "YYYY-MM-DD."}
          },
          required: ["name", "date_of_birth", "id_number", "entity_uen"]
        }
      },
      %{
        name: "create_asset",
        description:
          "Create a new asset (holding) owned by an entity. Only call this when the user clearly wants to add an asset, and after you have the required fields.",
        input_schema: %{
          type: "object",
          properties: %{
            name: %{type: "string", description: "Asset name or description."},
            code: %{type: "string", description: "Asset code or reference."},
            entity_uen: %{type: "string", description: "UEN of the entity that owns this asset."},
            type: %{type: "string", description: "Category, e.g. property, vehicle, equipment."},
            value: %{type: "number", description: "Monetary value."},
            acquisition_date: %{type: "string", description: "YYYY-MM-DD."}
          },
          required: ["name", "entity_uen"]
        }
      }
    ]
  end
end
