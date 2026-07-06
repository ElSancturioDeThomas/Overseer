defmodule Overseer.Repo.Migrations.AddRoleToPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add(:role, :string)
    end
  end
end
