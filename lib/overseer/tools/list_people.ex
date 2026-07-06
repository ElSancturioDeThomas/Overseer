defmodule Overseer.Tools.ListPeople do
  @moduledoc "Read-only tool: list people, optionally scoped to one entity."
  @behaviour EMCP.Tool

  alias Overseer.Management.EntityManagement
  alias Overseer.Management.PeopleManagement
  alias Overseer.Tools

  @impl EMCP.Tool
  def name, do: "list_people"

  @impl EMCP.Tool
  def description do
    "List people in the registry (directors, officers, shareholders), with name, designation, access level, ID number, date of birth, and the UEN of the entity they belong to. Optionally filter by entity_uen."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        entity_uen: %{
          type: :string,
          description: "Only list people belonging to the entity with this UEN."
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
        |> PeopleManagement.list_people_for_entity()
        |> Enum.map(&serialize(&1, entity.uen))
        |> Jason.encode!()
    end
  end

  def run(_args) do
    PeopleManagement.list_people()
    |> Enum.map(&serialize(&1, &1.entity && &1.entity.uen))
    |> Jason.encode!()
  end

  defp serialize(p, entity_uen) do
    %{
      id: p.id,
      name: p.name,
      designation: p.designation,
      access_level: p.access_level,
      id_number: p.id_number,
      dob: Tools.iso_date(p.dob),
      entity_uen: entity_uen
    }
  end
end
