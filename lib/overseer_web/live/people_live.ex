defmodule OverseerWeb.PeopleLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.PeopleManagement

  @impl true
  def mount(_params, _session, socket) do
    people = PeopleManagement.list_people_for_entity(socket.assigns.current_entity.id)

    {:ok, assign(socket, page_title: "People", people: people)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:people} current_entity={@current_entity}>
      <.header>
        People
        <:subtitle>Individuals associated with {@current_entity.uen}.</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/#{@current_entity.uen}/people/new"}>
            <.icon name="hero-plus" class="size-4" /> New Person
          </.button>
        </:actions>
      </.header>

      <.table
        id="people"
        rows={@people}
        row_click={fn person -> JS.navigate(~p"/#{@current_entity.uen}/people/#{person.id}/edit") end}
      >
        <:col :let={person} label="Name">{person.name}</:col>
        <:col :let={person} label="Designation">{person.designation}</:col>
        <:col :let={person} label="Access Level">{person.access_level}</:col>
        <:col :let={person} label="ID Number">{person.id_number}</:col>
        <:col :let={person} label="Date of Birth">{person.dob}</:col>
        <:action :let={person}>
          <.link navigate={~p"/#{@current_entity.uen}/people/#{person.id}/edit"} class="link link-primary">
            Edit
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
