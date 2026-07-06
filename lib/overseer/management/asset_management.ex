defmodule Overseer.Management.AssetManagement do
  import Ecto.Query

  alias Overseer.Repo
  alias Overseer.Registry.Asset

  @doc """
  Returns the list of all assets, each with their associated entity preloaded.
  """
  def list_assets do
    Asset
    |> Repo.all()
    |> Repo.preload(:entity)
  end

  @doc """
  Returns the list of assets belonging to the given entity.
  """
  def list_assets_for_entity(entity_id) do
    Asset
    |> where(entity_id: ^entity_id)
    |> Repo.all()
  end

  @doc """
  Gets a single asset by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  @doc """
  Gets a single asset by id, scoped to the given entity.
  Raises `Ecto.NoResultsError` if the asset does not exist or
  belongs to a different entity.
  """
  def get_asset!(entity_id, id) do
    Repo.get_by!(Asset, id: id, entity_id: entity_id)
  end

  @doc """
  Returns a changeset for tracking asset changes. Used to power forms.
  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  @doc """
  Creates a new asset in the database.
  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing asset in the database.
  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an existing asset from the database.
  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end
end
