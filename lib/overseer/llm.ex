defmodule Overseer.LLM do
  @moduledoc """
  Thin transport for calling Anthropic Claude models on AWS Bedrock.

  This module only knows how to *send* a request and hand back the decoded
  response. It does not decide what to say: the system prompt, the tools, and
  the tool-use loop all live in `Overseer.AIAgent`.
  """

  # The Bedrock model id (a global cross-region inference profile).
  @model_id "global.anthropic.claude-sonnet-4-6"
  @anthropic_version "bedrock-2023-05-31"
  @default_max_tokens 1024

  @doc """
  Sends messages to Claude and returns the decoded response body.

  Accepts either a single string (treated as one user message) or a list of
  messages in the Anthropic format
  (`%{role: "user" | "assistant", content: ...}`).

  Options:

    * `:system` - a system prompt string
    * `:tools` - a list of tool definitions
    * `:max_tokens` - defaults to #{@default_max_tokens}
    * `:model` - the Bedrock model id

  Returns `{:ok, body}` (the decoded JSON map) or `{:error, reason}`.
  """
  def chat(message_or_messages, opts \\ [])

  def chat(message, opts) when is_binary(message) do
    chat([%{role: "user", content: message}], opts)
  end

  def chat(messages, opts) when is_list(messages) do
    messages
    |> build_request(opts)
    |> ExAws.request()
  end

  defp build_request(messages, opts) do
    data =
      %{
        anthropic_version: @anthropic_version,
        max_tokens: Keyword.get(opts, :max_tokens, @default_max_tokens),
        messages: messages
      }
      |> maybe_put(:system, Keyword.get(opts, :system))
      |> maybe_put(:tools, Keyword.get(opts, :tools))

    model = Keyword.get(opts, :model, @model_id)

    %ExAws.Operation.JSON{
      http_method: :post,
      path: "/model/#{model}/invoke",
      service: :bedrock,
      data: data,
      headers: [{"content-type", "application/json"}]
    }
  end

  # Only include optional keys when there's a value, so we never send
  # `system: nil` or `tools: nil` to the API.
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
