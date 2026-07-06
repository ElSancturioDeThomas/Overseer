defmodule OverseerWeb.EntityLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.EntityManagement

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Entity", entities: EntityManagement.list_entities())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} sidebar={false}>
      <.header>
        Entity
        <:subtitle>Organisations and entities tracked by Overseer. Click one to open its workspace.</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/entity/new"}>
            <.icon name="hero-plus" class="size-4" /> New Entity
          </.button>
        </:actions>
      </.header>

      <.table
        id="entities"
        rows={@entities}
        row_click={fn entity -> JS.navigate(~p"/#{entity.uen}/home") end}
      >
        <:col :let={entity} label="UEN">{entity.uen}</:col>
        <:col :let={entity} label="Status">{entity.status}</:col>
        <:col :let={entity} label="Type">{entity.type}</:col>
        <:col :let={entity} label="Industry">{entity.industry}</:col>
        <:col :let={entity} label="Suburb">{entity.suburb}</:col>
        <:col :let={entity} label="Contact">{entity.contact_number}</:col>
        <:col :let={entity} label="Incorporated">{entity.incorporation_date}</:col>
        <:action :let={entity}>
          <.link navigate={~p"/#{entity.uen}/settings"} class="link link-primary">
            Settings
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
