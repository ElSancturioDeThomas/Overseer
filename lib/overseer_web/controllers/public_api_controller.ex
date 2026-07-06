defmodule OverseerWeb.PublicApiController do
  @moduledoc """
  The unauthenticated, opt-in public API (`/api/v1/:uen/...`).

  Unknown UENs and opted-out entities return an identical 404 so the
  endpoints don't reveal which entities exist in Overseer.
  """
  use OverseerWeb, :controller

  alias Overseer.Management.EntityManagement
  alias Overseer.PublicApi.BasicInfo
  alias Overseer.PublicApi.OpenApiSpec

  plug :public_headers

  def openapi(conn, %{"uen" => uen}) do
    case published_entity(uen) do
      nil -> not_found(conn)
      entity -> json(conn, OpenApiSpec.generate(entity, OverseerWeb.Endpoint.url()))
    end
  end

  def basic_info(conn, %{"uen" => uen}) do
    case published_entity(uen) do
      nil -> not_found(conn)
      entity -> json(conn, BasicInfo.serialize(entity))
    end
  end

  # An entity only "exists" for this API once it has published something.
  defp published_entity(uen) do
    with %{} = entity <- EntityManagement.get_entity_by_uen(uen),
         true <- BasicInfo.public?(entity) do
      entity
    else
      _ -> nil
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
