defmodule Overseer.Repo.Migrations.RenamePeopleRoleToAccessLevel do
  use Ecto.Migration

  def change do
    rename(table(:people), :role, to: :access_level)
  end
end
