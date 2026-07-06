defmodule Overseer.Registry.ApiConfig do
  @moduledoc """
  Per-entity public API configuration, embedded as JSONB on the entity.

  Each flag opts one section of the entity's data into the public,
  unauthenticated API. Everything defaults to off; the opt-in flag is
  the access control.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:basic_info_public, :boolean, default: false)
  end

  def changeset(api_config, attrs) do
    cast(api_config, attrs, [:basic_info_public])
  end
end
