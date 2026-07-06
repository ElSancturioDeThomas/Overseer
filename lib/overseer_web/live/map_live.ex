defmodule OverseerWeb.MapLive do
  use OverseerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Map",
       # Centre on St Georges Terrace, Perth for now.
       center: %{lat: -31.9557, lng: 115.8586},
       zoom: 15,
       # A sample marker until real geocoded entity/asset data is wired in.
       markers: [%{lat: -31.9557, lng: 115.8586, label: "St Georges Terrace"}]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:map} current_entity={@current_entity}>
      <.header>
        Map
        <:subtitle>Geographic view of {@current_entity.uen} and its assets.</:subtitle>
      </.header>

      <%!-- The Leaflet hook (app.js) reads these data-* attributes and renders the
            map into this element. phx-update="ignore" stops LiveView from touching
            the DOM that Leaflet manages. --%>
      <div
        id="overseer-map"
        phx-hook="LeafletMap"
        phx-update="ignore"
        class="mt-4 h-[70vh] w-full rounded-box border border-base-300"
        data-lat={@center.lat}
        data-lng={@center.lng}
        data-zoom={@zoom}
        data-markers={Jason.encode!(@markers)}
      >
      </div>
    </Layouts.app>
    """
  end
end
