defmodule Overseer.AIAgent do
  @moduledoc """
  The Overseer assistant agent.

  Owns the system prompt and the tool catalog, and runs the tool-use loop: it
  sends the conversation to the LLM, and whenever the model asks to use a tool
  it runs the matching function, feeds the result back, and asks again, until
  the model produces a final text answer.

  The transport (talking to Bedrock) lives in `Overseer.LLM`. Read-only tools
  are shared with the MCP server and live in `Overseer.Tools`; the write tools
  (create_person, create_asset) are defined here until the MCP endpoint has
  authentication.
  """

  alias Overseer.Management.AssetManagement
  alias Overseer.Management.EntityManagement
  alias Overseer.LLM
  alias Overseer.Management.PeopleManagement
  alias Overseer.Tools

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

  # --- Tool implementations -----------------------------------------------
  #
  # Read-only tools are shared modules in Overseer.Tools; only the write
  # tools are implemented here.

  defp run_tool("create_person", %{"entity_uen" => uen} = input) do
    with_entity(uen, fn entity ->
      attrs = %{
        "name" => input["name"],
        "dob" => input["date_of_birth"],
        "id_number" => input["id_number"],
        "designation" => input["designation"],
        "access_level" => input["access_level"],
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

  # Anything else is looked up in the shared read-only catalog.
  defp run_tool(name, input) do
    case Tools.fetch(name) do
      {:ok, module} -> module.run(input)
      :error -> Jason.encode!(%{error: "Unknown tool: #{name}"})
    end
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
    Enum.map(Tools.read_only(), &Tools.to_llm_spec/1) ++ write_tools()
  end

  defp write_tools do
    [
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
            access_level: %{type: "string", description: "The person's access level."},
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
