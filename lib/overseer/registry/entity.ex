defmodule Overseer.Registry.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  # This explicitly tells Ecto which Postgres table this struct belongs to
  schema "entities" do
    field(:uen, :string)
    field(:status, :string)
    field(:type, :string)
    field(:incorporation_date, :date)
    field(:address, :string)
    field(:industry, :string)
    field(:suburb, :string)
    field(:contact_number, :string)

    embeds_one(:api_config, Overseer.Registry.ApiConfig, on_replace: :update)

    # This automatically adds inserted_at and updated_at timestamps!
    timestamps()
  end

  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [
      :uen,
      :status,
      :type,
      :incorporation_date,
      :address,
      :industry,
      :suburb,
      :contact_number
    ])
    |> validate_required([:uen])
    # Catches the DB unique index violation and turns it into a changeset
    # error instead of raising an exception.
    |> unique_constraint(:uen)
  end
end
