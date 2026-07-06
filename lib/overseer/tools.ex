defmodule Overseer.Tools do
  @moduledoc """
  The shared tool catalog.

  Each tool is a module implementing the `EMCP.Tool` behaviour plus a
  `run/1` function that returns its result as a JSON string. That one
  definition serves two consumers:

    * `Overseer.MCPServer` exposes the modules to external MCP clients
      (Claude Code, Claude Desktop, the MCP Inspector).
    * `Overseer.AIAgent` converts them into LLM tool specs with
      `to_llm_spec/1` and dispatches calls through `fetch/1`.

  Only read-only tools live here for now; the agent's write tools
  (create_person, create_asset) stay private to it until the MCP
  endpoint has authentication.
  """

  @read_only [
    Overseer.Tools.ListEntities,
    Overseer.Tools.ListPeople,
    Overseer.Tools.ListAssets,
    Overseer.Tools.LookupAcraProfile,
    Overseer.Tools.SearchMemory
  ]

  @doc "All read-only tool modules."
  def read_only, do: @read_only

  @doc "Finds a tool module by its wire name."
  def fetch(name) do
    case Enum.find(@read_only, &(&1.name() == name)) do
      nil -> :error
      module -> {:ok, module}
    end
  end

  @doc """
  Converts a tool module into the spec shape the LLM API expects
  (`%{name, description, input_schema}`).
  """
  def to_llm_spec(module) do
    %{
      name: module.name(),
      description: module.description(),
      input_schema: module.input_schema()
    }
  end

  @doc "Formats a date as ISO 8601, passing nil through."
  def iso_date(nil), do: nil
  def iso_date(%Date{} = date), do: Date.to_iso8601(date)
end
