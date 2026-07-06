defmodule Overseer.Registry.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  # This explicitly tells Ecto which Postgres table this struct belongs to
  schema "entities" do
    field(:uen, :string)
    field(:status, :string)
    field(:type, :string)
    field(:incorporation_date, :date)
    field(:address, :string)
    field(:industry, :string)
    field(:suburb, :string)
    field(:contact_number, :string)
    field(:custom_domain, :string)

    embeds_one(:api_config, Overseer.Registry.ApiConfig, on_replace: :update)

    # This automatically adds inserted_at and updated_at timestamps!
    timestamps()
  end

  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [
      :uen,
      :status,
      :type,
      :incorporation_date,
      :address,
      :industry,
      :suburb,
      :contact_number
    ])
    |> validate_required([:uen])
    # Catches the DB unique index violation and turns it into a changeset
    # error instead of raising an exception.
    |> unique_constraint(:uen)
  end

  @doc """
  Changeset for the entity's public API custom domain. Normalizes
  whatever the user pastes (scheme, trailing slash, mixed case) down
  to a bare hostname; an empty value clears the domain.
  """
  def custom_domain_changeset(entity, attrs) do
    entity
    |> cast(attrs, [:custom_domain])
    |> update_change(:custom_domain, &normalize_domain/1)
    |> validate_format(:custom_domain, ~r/^[a-z0-9][a-z0-9-]*(\.[a-z0-9][a-z0-9-]*)+$/,
      message: "must be a hostname like api.example.com"
    )
    |> unique_constraint(:custom_domain,
      message: "is already in use by another entity"
    )
  end

  defp normalize_domain(nil), do: nil

  defp normalize_domain(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r{^https?://}, "")
    |> String.trim_trailing("/")
    |> String.trim_trailing(".")
    |> case do
      "" -> nil
      host -> host
    end
  end
end
