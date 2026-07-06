defmodule OverseerWeb.McpLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "MCP")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:mcp}>
      <.header>
        MCP
        <:subtitle>Model Context Protocol servers.</:subtitle>
      </.header>

      <p class="mt-4 text-base-content/70">
        This is the MCP page. Connected MCP servers will live here.
      </p>
    </Layouts.app>
    """
  end
end
