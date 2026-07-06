defmodule Overseer.Management.SopManagement do
  import Ecto.Query

  alias Overseer.Repo
  alias Overseer.Registry.Sop

  @doc """
  Returns the list of all SOPs, each with their associated entity preloaded.
  """
  def list_sops do
    Sop
    |> Repo.all()
    |> Repo.preload(:entity)
  end

  @doc """
  Returns the list of SOPs belonging to the given entity.
  """
  def list_sops_for_entity(entity_id) do
    Sop
    |> where(entity_id: ^entity_id)
    |> order_by(asc: :title)
    |> Repo.all()
  end

  @doc """
  Gets a single SOP by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_sop!(id), do: Repo.get!(Sop, id)

  @doc """
  Gets a single SOP by id, scoped to the given entity.
  Raises `Ecto.NoResultsError` if the SOP does not exist or
  belongs to a different entity.
  """
  def get_sop!(entity_id, id) do
    Repo.get_by!(Sop, id: id, entity_id: entity_id)
  end

  @doc """
  Returns a changeset for tracking SOP changes. Used to power forms.
  """
  def change_sop(%Sop{} = sop, attrs \\ %{}) do
    Sop.changeset(sop, attrs)
  end

  @doc """
  Creates a new SOP in the database.
  """
  def create_sop(attrs \\ %{}) do
    %Sop{}
    |> Sop.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing SOP in the database.
  """
  def update_sop(%Sop{} = sop, attrs) do
    sop
    |> Sop.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an existing SOP from the database.
  """
  def delete_sop(%Sop{} = sop) do
    Repo.delete(sop)
  end
end
