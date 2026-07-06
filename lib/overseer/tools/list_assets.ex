defmodule Overseer.Tools.ListAssets do
  @moduledoc "Read-only tool: list assets, optionally scoped to one entity."
  @behaviour EMCP.Tool

  alias Overseer.Management.AssetManagement
  alias Overseer.Management.EntityManagement
  alias Overseer.Tools

  @impl EMCP.Tool
  def name, do: "list_assets"

  @impl EMCP.Tool
  def description do
    "List assets (holdings) in the registry, with their name, code, type, value, acquisition date, and the UEN of the entity that owns them. Optionally filter by entity_uen."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        entity_uen: %{
          type: :string,
          description: "Only list assets owned by the entity with this UEN."
        }
      },
      required: []
    }
  end

  @impl EMCP.Tool
  def annotations, do: %{readOnlyHint: true}

  @impl EMCP.Tool
  def call(_conn, args) do
    EMCP.Tool.response([%{"type" => "text", "text" => run(args)}])
  end

  @doc "Runs the tool, returning the result as a JSON string."
  def run(args \\ %{})

  def run(%{"entity_uen" => uen}) when is_binary(uen) do
    case EntityManagement.get_entity_by_uen(uen) do
      nil ->
        Jason.encode!(%{error: "No entity found with UEN #{uen}"})

      entity ->
        entity.id
        |> AssetManagement.list_assets_for_entity()
        |> Enum.map(&serialize(&1, entity.uen))
        |> Jason.encode!()
    end
  end

  def run(_args) do
    AssetManagement.list_assets()
    |> Enum.map(&serialize(&1, &1.entity && &1.entity.uen))
    |> Jason.encode!()
  end

  defp serialize(a, entity_uen) do
    %{
      id: a.id,
      name: a.name,
      code: a.code,
      type: a.type,
      value: a.value && to_string(a.value),
      acquisition_date: Tools.iso_date(a.acquisition_date),
      entity_uen: entity_uen
    }
  end
end
