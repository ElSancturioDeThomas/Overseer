defmodule Overseer.Tools.ListEntities do
  @behaviour EMCP.Tool

  @impl EMCP.Tool
  def name, do: "list_entities"

  @impl EMCP.Tool
  def description, do: "Lists all entities in the database"

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{},
      required: []
    }
  end

  @impl EMCP.Tool
  def call(_conn, _args) do
    entities = Overseer.Management.EntityManagement.list_entities()
    
    simplified_entities = Enum.map(entities, fn e -> 
      e
      |> Map.from_struct()
      |> Map.drop([:__meta__])
    end)

    json = Jason.encode!(simplified_entities)
    
    EMCP.Tool.response([%{"type" => "text", "text" => json}])
  end
end
