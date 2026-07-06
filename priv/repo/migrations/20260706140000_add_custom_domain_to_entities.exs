defmodule Overseer.Repo.Migrations.AddCustomDomainToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add(:custom_domain, :string)
    end

    create(unique_index(:entities, [:custom_domain]))
  end
end
