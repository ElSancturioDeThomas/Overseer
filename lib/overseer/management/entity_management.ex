defmodule Overseer.Management.EntityManagement do
  alias Overseer.Repo
  alias Overseer.Registry.Entity

  @doc """
  Returns the list of all entities in the database.
  """
  def list_entities do
    Repo.all(Entity)
  end

  @doc """
  Gets a single entity by its UEN, or nil if none matches.
  """
  def get_entity_by_uen(uen) do
    Repo.get_by(Entity, uen: uen)
  end

  @doc """
  Gets a single entity by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_entity!(id), do: Repo.get!(Entity, id)

  @doc """
  Returns a changeset for tracking entity changes. Used to power forms.
  """
  def change_entity(%Entity{} = entity, attrs \\ %{}) do
    Entity.changeset(entity, attrs)
  end

  @doc """
  Updates an existing entity in the database.
  """
  def update_entity(%Entity{} = entity, attrs) do
    entity
    |> Entity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a new entity in the database.
  """
  def create_entity(attrs \\ %{}) do
    %Entity{}
    |> Entity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an existing entity from the database.
  """
  def delete_entity(%Entity{} = entity) do
    Repo.delete(entity)
  end
end
