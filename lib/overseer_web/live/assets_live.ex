defmodule OverseerWeb.AssetsLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.AssetManagement

  @impl true
  def mount(_params, _session, socket) do
    assets = AssetManagement.list_assets_for_entity(socket.assigns.current_entity.id)

    {:ok, assign(socket, page_title: "Assets", assets: assets)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:assets} current_entity={@current_entity}>
      <.header>
        Assets
        <:subtitle>Holdings and assets associated with {@current_entity.uen}.</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/#{@current_entity.uen}/assets/new"}>
            <.icon name="hero-plus" class="size-4" /> New Asset
          </.button>
        </:actions>
      </.header>

      <.table id="assets" rows={@assets}>
        <:col :let={asset} label="Name">{asset.name}</:col>
        <:col :let={asset} label="Code">{asset.code}</:col>
        <:col :let={asset} label="Type">{asset.type}</:col>
        <:col :let={asset} label="Value">{asset.value}</:col>
        <:col :let={asset} label="Acquired">{asset.acquisition_date}</:col>
        <:action :let={asset}>
          <.link navigate={~p"/#{@current_entity.uen}/assets/#{asset.id}/edit"} class="link link-primary">
            Edit
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
