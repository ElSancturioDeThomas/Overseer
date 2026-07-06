defmodule Overseer.Repo.Migrations.CreateEntities do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add(:uen, :string)
      add(:status, :string)
      add(:type, :string)
      add(:incorporation_date, :date)
      timestamps()
    end

    create(unique_index(:entities, [:uen]))
  end
end
