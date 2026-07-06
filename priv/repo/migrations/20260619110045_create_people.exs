defmodule Overseer.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add(:name, :string)
      add(:dob, :date)
      add(:id_number, :string)
      add(:residential_address, :string)
      add(:appointment_date, :date)
      add(:resignation_date, :date)
      add(:designation, :string)
      add(:entity_id, references(:entities, on_delete: :delete_all))
      timestamps()
    end

    create(index(:people, [:entity_id]))
  end
end
