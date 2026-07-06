defmodule Overseer.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add(:name, :string)
      add(:type, :string)
      add(:value, :decimal)
      add(:acquisition_date, :date)
      add(:entity_id, references(:entities, on_delete: :delete_all))
      timestamps()
    end

    create(index(:assets, [:entity_id]))
  end
end
