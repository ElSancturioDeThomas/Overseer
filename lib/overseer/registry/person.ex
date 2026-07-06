defmodule Overseer.Registry.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field(:name, :string)
    field(:dob, :date)
    field(:id_number, :string)
    field(:residential_address, :string)
    field(:appointment_date, :date)
    field(:resignation_date, :date)
    field(:designation, :string)
    field(:access_level, :string)

    belongs_to(:entity, Overseer.Registry.Entity)
    timestamps()
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :name,
      :dob,
      :id_number,
      :residential_address,
      :appointment_date,
      :resignation_date,
      :designation,
      :access_level,
      :entity_id
    ])
    |> validate_required([:name, :dob, :id_number, :entity_id])
  end
end
