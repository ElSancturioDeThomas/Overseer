defmodule Overseer.Tools.ListEntities do
  @moduledoc "Read-only tool: list every entity in the registry."
  @behaviour EMCP.Tool

  alias Overseer.Management.EntityManagement
  alias Overseer.Tools

  @impl EMCP.Tool
  def name, do: "list_entities"

  @impl EMCP.Tool
  def description do
    "List all entities (companies) in the Overseer registry, with their UEN, status, type, and incorporation date."
  end

  @impl EMCP.Tool
  def input_schema do
    %{type: :object, properties: %{}, required: []}
  end

  @impl EMCP.Tool
  def annotations, do: %{readOnlyHint: true}

  @impl EMCP.Tool
  def call(_conn, args) do
    EMCP.Tool.response([%{"type" => "text", "text" => run(args)}])
  end

  @doc "Runs the tool, returning the result as a JSON string."
  def run(_args \\ %{}) do
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
        incorporation_date: Tools.iso_date(e.incorporation_date)
      }
    end)
    |> Jason.encode!()
  end
end
