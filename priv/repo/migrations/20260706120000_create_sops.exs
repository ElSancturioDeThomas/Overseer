defmodule Overseer.Repo.Migrations.CreateSops do
  use Ecto.Migration

  def change do
    create table(:sops) do
      add(:title, :string)
      add(:content, :text)
      add(:entity_id, references(:entities, on_delete: :delete_all))
      timestamps()
    end

    create(index(:sops, [:entity_id]))
  end
end
