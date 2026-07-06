defmodule OverseerWeb.ApiLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "API")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:api}>
      <.header>
        API
        <:subtitle>API keys and programmatic access.</:subtitle>
      </.header>

      <p class="mt-4 text-base-content/70">
        This is the API page. Keys and documentation will live here.
      </p>
    </Layouts.app>
    """
  end
end
