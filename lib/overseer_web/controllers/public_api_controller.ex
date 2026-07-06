defmodule OverseerWeb.PublicApiController do
  @moduledoc """
  The unauthenticated, opt-in public API.

  Reachable two ways: path-style on the canonical host
  (`/api/v1/:uen/...`) and host-style on an entity's custom domain
  (`/openapi.json`, `/basic-info`), where `Plugs.PublicApiDomain` has
  already resolved the entity from the Host header.

  Unknown UENs and opted-out entities return an identical 404 so the
  endpoints don't reveal which entities exist in Overseer.
  """
  use OverseerWeb, :controller

  alias Overseer.Management.EntityManagement
  alias Overseer.PublicApi.BasicInfo
  alias Overseer.PublicApi.OpenApiSpec

  plug :public_headers

  def openapi(conn, params) do
    case published_entity(conn, params) do
      nil -> not_found(conn)
      entity -> json(conn, OpenApiSpec.generate(entity, server_url(conn, entity)))
    end
  end

  def basic_info(conn, params) do
    case published_entity(conn, params) do
      nil -> not_found(conn)
      entity -> json(conn, BasicInfo.serialize(entity))
    end
  end

  # An entity only "exists" for this API once it has published something.
  defp published_entity(conn, params) do
    entity = conn.assigns[:public_entity] || lookup_by_uen(params["uen"])
    if entity && BasicInfo.public?(entity), do: entity
  end

  defp lookup_by_uen(uen) when is_binary(uen), do: EntityManagement.get_entity_by_uen(uen)
  defp lookup_by_uen(_), do: nil

  # The spec's servers URL must match how this request arrived: the
  # custom domain serves the API at its root, the canonical host under
  # /api/v1/:uen.
  defp server_url(%{assigns: %{public_entity: %{}}} = conn, _entity), do: base_url(conn)

  defp server_url(_conn, entity) do
    "#{OverseerWeb.Endpoint.url()}/api/v1/#{entity.uen}"
  end

  defp base_url(conn) do
    case get_req_header(conn, "x-forwarded-proto") do
      ["https" | _] ->
        "https://#{conn.host}"

      _ ->
        port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"
        "#{conn.scheme}://#{conn.host}#{port}"
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not found"})
  end

  # Everything behind these routes is deliberately public, so permissive
  # CORS is safe, and cache headers keep crawler traffic off the app.
  defp public_headers(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, OPTIONS")
    |> put_resp_header("cache-control", "public, max-age=300")
  end
end
