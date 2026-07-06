defmodule OverseerWeb.IntegrationsLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Integrations")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:integrations}>
      <.header>
        Integrations
        <:subtitle>Connect Overseer to external services.</:subtitle>
      </.header>

      <p class="mt-4 text-base-content/70">
        This is the Integrations page. Connected services will live here.
      </p>
    </Layouts.app>
    """
  end
end
