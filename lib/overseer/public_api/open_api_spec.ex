defmodule Overseer.PublicApi.OpenApiSpec do
  @moduledoc """
  Generates the per-entity OpenAPI 3.1 document for the public API.

  Only sections the entity has opted into appear in the spec, so the
  document is safe to publish anywhere (including on the org's own
  domain as `/.well-known/openapi.json`). The `servers` URL points back
  at Overseer, which is what routes agent calls to us regardless of
  where the file is hosted.
  """

  alias Overseer.PublicApi.BasicInfo

  @doc """
  Builds the OpenAPI document map for the given entity.

  `base_url` is the public root of this Overseer instance,
  e.g. `https://overseer-app.fly.dev`.
  """
  def generate(entity, base_url) do
    %{
      openapi: "3.1.0",
      info: %{
        title: "#{entity.uen} public API",
        description:
          "Public information that entity #{entity.uen} has chosen to publish " <>
            "via Overseer. All endpoints are read-only and require no authentication.",
        version: "1.0.0"
      },
      servers: [%{url: "#{base_url}/api/v1/#{entity.uen}"}],
      paths: paths(entity)
    }
  end

  defp paths(entity) do
    if BasicInfo.public?(entity) do
      %{"/basic-info" => basic_info_path()}
    else
      %{}
    end
  end

  defp basic_info_path do
    %{
      get: %{
        operationId: "getBasicInfo",
        summary: "Get the entity's basic information",
        description:
          "Returns the entity's public profile: registration details, " <>
            "industry, and contact information.",
        responses: %{
          "200" => %{
            description: "The entity's basic information.",
            content: %{"application/json" => %{schema: BasicInfo.openapi_schema()}}
          },
          "404" => %{description: "Unknown entity, or this section is not published."}
        }
      }
    }
  end
end
