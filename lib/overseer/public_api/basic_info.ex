defmodule Overseer.PublicApi.BasicInfo do
  @moduledoc """
  The publicly-safe view of an entity's basic information.

  What is public is defined here and only here: every surface that
  exposes basic info (REST endpoint, OpenAPI schema, future public MCP
  tool) must go through this module. Never add PII to this serializer.
  """

  alias Overseer.Tools

  @doc "Whether the entity has opted its basic info into the public API."
  def public?(%{api_config: %{basic_info_public: true}}), do: true
  def public?(_entity), do: false

  @doc "Serializes the entity's basic information for public consumption."
  def serialize(entity) do
    %{
      uen: entity.uen,
      status: entity.status,
      type: entity.type,
      industry: entity.industry,
      address: entity.address,
      suburb: entity.suburb,
      contact_number: entity.contact_number,
      incorporation_date: Tools.iso_date(entity.incorporation_date)
    }
  end

  @doc "The OpenAPI schema describing the `serialize/1` response shape."
  def openapi_schema do
    %{
      type: :object,
      properties: %{
        uen: %{type: :string, description: "Unique Entity Number"},
        status: %{type: [:string, :null]},
        type: %{type: [:string, :null], description: "Entity type"},
        industry: %{type: [:string, :null]},
        address: %{type: [:string, :null]},
        suburb: %{type: [:string, :null]},
        contact_number: %{type: [:string, :null]},
        incorporation_date: %{
          type: [:string, :null],
          format: :date,
          description: "ISO 8601 date"
        }
      },
      required: [:uen]
    }
  end
end
