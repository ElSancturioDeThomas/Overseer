defmodule OverseerWeb.HomeLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    {:ok,
     assign(socket,
       page_title: "Home",
       weekday: Calendar.strftime(today, "%A"),
       full_date: Calendar.strftime(today, "%A, %-d %B %Y")
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:home} current_entity={@current_entity}>
      <.header>
        {@current_entity.uen}
        <:subtitle>Your company at a glance.</:subtitle>
      </.header>

      <p class="mt-4 text-2xl font-semibold">Happy {@weekday}!</p>
      <p class="text-base-content/70">{@full_date}</p>
    </Layouts.app>
    """
  end
end
