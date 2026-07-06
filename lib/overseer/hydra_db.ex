defmodule Overseer.HydraDB do
  @moduledoc """
  Thin REST client for the HydraDB API (https://api.hydradb.com).

  HydraDB is a context-management platform for LLM apps: it ingests and stores
  knowledge and user "memories" in isolated tenants (workspaces) and retrieves
  them via hybrid/text search. See https://docs.hydradb.com/api-reference/v2.

  Every request carries the `Authorization: Bearer <key>` and `API-Version: 2`
  headers. The base URL and key come from application config, which
  `config/runtime.exs` populates from the `HYDRADB_API_KEY` env var.

  Functions return `{:ok, data}` (the `data` field of HydraDB's response
  envelope) or `{:error, reason}`.
  """

  # --- Wrappers for the documented endpoints ---------------------------

  @doc "List the workspaces (tenants) available to your API key."
  def list_tenants, do: request(:get, "/tenants")

  @doc "Create a new workspace. See the docs for the expected body."
  def create_tenant(body) when is_map(body), do: request(:post, "/tenants", json: body)

  @doc """
  Store one or more user/assistant exchanges as a "memory" in a workspace.

  `pairs` is a list of `%{user: "...", assistant: "..."}` maps. The
  `/context/ingest` endpoint is multipart/form-data, so the memory payload is
  JSON-stringified into a form field.

  Options: `:tenant_id` (default `"default-tenant"`), `:sub_tenant_id`, `:title`.
  """
  def ingest_memory(pairs, opts \\ []) when is_list(pairs) do
    memory = %{
      title: opts[:title] || "Assistant conversation",
      user_assistant_pairs: Enum.map(pairs, &%{user: &1.user, assistant: &1.assistant})
    }

    fields =
      [
        type: "memory",
        tenant_id: opts[:tenant_id] || "default-tenant",
        memories: Jason.encode!([memory])
      ]
      |> maybe_put(:sub_tenant_id, opts[:sub_tenant_id])

    request(:post, "/context/ingest", form_multipart: fields)
  end

  @doc "Retrieve context via hybrid or text search. Body fields per the docs."
  def query(body) when is_map(body), do: request(:post, "/query", json: body)

  @doc """
  Escape hatch for any endpoint not wrapped above. Pass `:params` for query
  string values and a body map to `post/3`.

      Overseer.HydraDB.get("/tenants/stats", params: [tenant_id: "abc"])
      Overseer.HydraDB.post("/context/list", %{tenant_id: "abc"})
  """
  def get(path, opts \\ []), do: request(:get, path, opts)
  def post(path, body, opts \\ []), do: request(:post, path, Keyword.put(opts, :json, body))
  def delete(path, opts \\ []), do: request(:delete, path, opts)

  # --- Transport -------------------------------------------------------

  defp request(method, path, opts \\ []) do
    conf = config()

    [
      method: method,
      url: conf.base_url <> path,
      headers: [
        {"authorization", "Bearer #{conf.api_key}"},
        {"api-version", "2"}
      ]
    ]
    |> maybe_put(:json, opts[:json])
    |> maybe_put(:form_multipart, opts[:form_multipart])
    |> maybe_put(:params, opts[:params])
    |> Req.request()
    |> handle_response()
  end

  # HydraDB wraps every payload in {success, data, error, meta}; unwrap it.
  defp handle_response({:ok, %Req.Response{status: status, body: %{"success" => true} = body}})
       when status in 200..299 do
    {:ok, body["data"]}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, exception}), do: {:error, exception}

  defp config do
    conf = Application.get_env(:overseer, __MODULE__, [])

    %{
      base_url: conf[:base_url] || "https://api.hydradb.com",
      api_key: conf[:api_key] || System.get_env("HYDRADB_API_KEY")
    }
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
