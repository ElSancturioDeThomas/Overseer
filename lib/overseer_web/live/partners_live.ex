defmodule OverseerWeb.PartnersLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Partners")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:partners}>
      <.header>
        Partners
        <:subtitle>Suppliers, vendors, and partners associated with your entities.</:subtitle>
      </.header>

      <p class="mt-4 text-base-content/70">
        This is the Partners page. Suppliers, vendors, and partner records will live here.
      </p>
    </Layouts.app>
    """
  end
end
