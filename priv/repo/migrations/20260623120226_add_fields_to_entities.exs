defmodule Overseer.Repo.Migrations.AddFieldsToEntities do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add(:address, :string)
      add(:industry, :string)
      add(:suburb, :string)
      add(:contact_number, :string)
    end
  end
end
