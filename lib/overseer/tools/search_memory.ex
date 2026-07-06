defmodule Overseer.Tools.SearchMemory do
  @moduledoc "Read-only tool: search stored memories and ingested context in HydraDB."
  @behaviour EMCP.Tool

  alias Overseer.HydraDB

  @impl EMCP.Tool
  def name, do: "search_memory"

  @impl EMCP.Tool
  def description do
    "Search stored memories and knowledge from previous conversations and ingested context. Use this to recall what was discussed earlier or to find relevant background before answering."
  end

  @impl EMCP.Tool
  def input_schema do
    %{
      type: :object,
      properties: %{
        query: %{
          type: :string,
          description: "What to search for: a topic, question, or keywords."
        }
      },
      required: ["query"]
    }
  end

  @impl EMCP.Tool
  def annotations, do: %{readOnlyHint: true}

  @impl EMCP.Tool
  def call(_conn, args) do
    EMCP.Tool.response([%{"type" => "text", "text" => run(args)}])
  end

  @doc "Runs the tool, returning the result as a JSON string."
  def run(%{"query" => query}) when is_binary(query) do
    case HydraDB.query(%{tenant_id: "default-tenant", query: query, type: "all", max_results: 5}) do
      {:ok, data} ->
        data
        |> Map.get("chunks", [])
        |> Enum.map(fn chunk ->
          %{
            content: chunk["chunk_content"],
            source: chunk["source_title"],
            score: chunk["relevancy_score"]
          }
        end)
        |> Jason.encode!()

      {:error, reason} ->
        Jason.encode!(%{error: "Memory search failed: #{inspect(reason)}"})
    end
  end

  def run(_args) do
    Jason.encode!(%{error: "Missing required argument: query"})
  end
end
