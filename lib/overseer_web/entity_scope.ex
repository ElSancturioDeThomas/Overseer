defmodule OverseerWeb.EntityScope do
  @moduledoc """
  LiveView `on_mount` hook for routes scoped to a single entity.

  Routes under `/:uen/...` use this hook (via the router's `live_session`)
  to resolve the UEN into an entity and assign it as `:current_entity`.
  Unknown UENs redirect back to the entity list.
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias Overseer.Management.EntityManagement

  def on_mount(:default, %{"uen" => uen}, _session, socket) do
    case EntityManagement.get_entity_by_uen(uen) do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, "No entity found with UEN #{uen}")
         |> redirect(to: "/")}

      entity ->
        {:cont, assign(socket, :current_entity, entity)}
    end
  end
end
