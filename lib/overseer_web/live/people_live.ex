defmodule OverseerWeb.PeopleLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.PeopleManagement

  @impl true
  def mount(_params, _session, socket) do
    people = PeopleManagement.list_people()

    {:ok, assign(socket, page_title: "People", people: people)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:people}>
      <.header>
        People
        <:subtitle>Individuals associated with your entities.</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/people/new"}>
            <.icon name="hero-plus" class="size-4" /> New Person
          </.button>
        </:actions>
      </.header>

      <.table id="people" rows={@people}>
        <:col :let={person} label="Name">{person.name}</:col>
        <:col :let={person} label="Designation">{person.designation}</:col>
        <:col :let={person} label="Role">{person.role}</:col>
        <:col :let={person} label="ID Number">{person.id_number}</:col>
        <:col :let={person} label="Date of Birth">{person.dob}</:col>
        <:col :let={person} label="Entity (UEN)">{person.entity.uen}</:col>
        <:action :let={person}>
          <.link navigate={~p"/people/#{person.id}/edit"} class="link link-primary">
            Edit
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
