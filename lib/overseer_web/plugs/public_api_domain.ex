defmodule OverseerWeb.Plugs.PublicApiDomain do
  @moduledoc """
  Serves the public API on entities' custom domains.

  An org CNAMEs a subdomain (e.g. api.heal.enterprises) at this app and
  registers it on their API page. Requests arriving on that host get the
  entity assigned to `:public_entity`, and only the public API paths are
  let through — everything else 404s so the Overseer UI is never served
  on a customer's domain. Requests on the canonical host pass straight
  through untouched.
  """
  import Plug.Conn

  alias Overseer.Management.EntityManagement

  @public_paths ["/openapi.json", "/basic-info", "/.well-known/openapi.json"]

  def init(opts), do: opts

  def call(conn, _opts) do
    with false <- canonical_host?(conn),
         %{} = entity <- EntityManagement.get_entity_by_custom_domain(conn.host) do
      scope_to_entity(conn, entity)
    else
      _ -> conn
    end
  end

  defp scope_to_entity(conn, entity) do
    if conn.request_path in @public_paths do
      assign(conn, :public_entity, entity)
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(404, ~s({"error":"not found"}))
      |> halt()
    end
  end

  defp canonical_host?(conn) do
    app_host = OverseerWeb.Endpoint.config(:url)[:host] || "localhost"
    conn.host in [app_host, "localhost", "127.0.0.1"]
  end
end
