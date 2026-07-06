defmodule Overseer.Management.PeopleManagement do
  import Ecto.Query

  alias Overseer.Repo
  alias Overseer.Registry.Person

  @doc """
  Returns the list of all people, each with their associated entity preloaded.
  """
  def list_people do
    Person
    |> Repo.all()
    |> Repo.preload(:entity)
  end

  @doc """
  Returns the list of people belonging to the given entity.
  """
  def list_people_for_entity(entity_id) do
    Person
    |> where(entity_id: ^entity_id)
    |> Repo.all()
  end

  @doc """
  Gets a single person by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_person!(id), do: Repo.get!(Person, id)

  @doc """
  Gets a single person by id, scoped to the given entity.
  Raises `Ecto.NoResultsError` if the person does not exist or
  belongs to a different entity.
  """
  def get_person!(entity_id, id) do
    Repo.get_by!(Person, id: id, entity_id: entity_id)
  end

  @doc """
  Returns a changeset for tracking person changes. Used to power forms.
  """
  def change_person(%Person{} = person, attrs \\ %{}) do
    Person.changeset(person, attrs)
  end

  @doc """
  Creates a new person in the database.
  """
  def create_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing person in the database.
  """
  def update_person(%Person{} = person, attrs) do
    person
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an existing person from the database.
  """
  def delete_person(%Person{} = person) do
    Repo.delete(person)
  end
end
