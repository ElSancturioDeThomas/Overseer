defmodule Overseer.Tools.LookupAcraProfile do
  @moduledoc "Read-only tool: fetch an official ACRA business profile by UEN."
  @behaviour EMCP.Tool

  alias Overseer.Acra

  @impl EMCP.Tool
  def name, do: "lookup_acra_profile"

  @impl EMCP.Tool
  def description do
    "Look up an official ACRA business profile for a Singapore entity by its UEN. Use for authoritative company details not stored locally."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        uen: %{type: :string, description: "The Unique Entity Number, e.g. \"16888888A\"."}
      },
      required: ["uen"]
    }
  end

  @impl EMCP.Tool
  def annotations, do: %{readOnlyHint: true, openWorldHint: true}

  @impl EMCP.Tool
  def call(_conn, args) do
    EMCP.Tool.response([%{"type" => "text", "text" => run(args)}])
  end

  @doc "Runs the tool, returning the result as a JSON string."
  def run(%{"uen" => uen}) when is_binary(uen) do
    case Acra.get_business_profile(uen) do
      {:ok, profile} -> profile |> Map.from_struct() |> Jason.encode!()
      {:error, _reason} -> Jason.encode!(%{error: "Could not fetch ACRA profile for #{uen}"})
    end
  end

  def run(_args) do
    Jason.encode!(%{error: "Missing required argument: uen"})
  end
end
