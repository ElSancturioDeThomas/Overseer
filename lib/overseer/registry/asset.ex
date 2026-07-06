defmodule Overseer.Registry.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assets" do
    field(:name, :string)
    field(:code, :string)
    field(:type, :string)
    field(:value, :decimal)
    field(:acquisition_date, :date)

    belongs_to(:entity, Overseer.Registry.Entity)
    timestamps()
  end

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:name, :code, :type, :value, :acquisition_date, :entity_id])
    |> validate_required([:name, :entity_id])
  end
end
