defmodule Overseer.Registry.Sop do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sops" do
    field(:title, :string)
    field(:content, :string)

    belongs_to(:entity, Overseer.Registry.Entity)
    timestamps()
  end

  def changeset(sop, attrs) do
    sop
    |> cast(attrs, [:title, :content, :entity_id])
    |> validate_required([:title, :entity_id])
  end
end
