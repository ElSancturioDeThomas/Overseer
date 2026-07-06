defmodule Overseer.Repo.Migrations.AddApiConfigToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add(:api_config, :map, default: %{}, null: false)
    end
  end
end
