defmodule Overseer.Management.EntityManagementTest do
  use Overseer.DataCase

  alias Overseer.Management.EntityManagement
  alias Overseer.Registry.Entity
  alias Overseer.Repo

  setup do
    # Check out a sandboxed DB connection for this test. Everything done
    # here runs in a transaction that is rolled back when the test finishes.
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "create_entity/1" do
    test "inserts an entity when given valid attrs" do
      attrs = %{uen: "16888888A", status: "LIVE", type: "Company"}

      assert {:ok, %Entity{} = entity} = EntityManagement.create_entity(attrs)
      assert entity.id
      assert entity.uen == "16888888A"
      assert entity.status == "LIVE"
    end

    test "returns an error changeset when uen is missing" do
      assert {:error, changeset} = EntityManagement.create_entity(%{status: "LIVE"})
      refute changeset.valid?
      assert %{uen: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects a duplicate uen" do
      attrs = %{uen: "16888888A"}
      assert {:ok, _entity} = EntityManagement.create_entity(attrs)

      assert {:error, changeset} = EntityManagement.create_entity(attrs)
      refute changeset.valid?
    end
  end

  describe "delete_entity/1" do
    test "removes an existing entity" do
      {:ok, entity} = EntityManagement.create_entity(%{uen: "99999999X"})

      assert {:ok, %Entity{}} = EntityManagement.delete_entity(entity)
      refute Repo.get(Entity, entity.id)
    end
  end
end
