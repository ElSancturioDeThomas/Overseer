defmodule OverseerWeb.PeopleLive.Form do
  use OverseerWeb, :live_view

  alias Overseer.Management.PeopleManagement
  alias Overseer.Management.EntityManagement
  alias Overseer.Registry.Person

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:people}>
      <.header>
        {@page_title}
        <:subtitle>Fields marked required must be filled in.</:subtitle>
      </.header>

      <.form for={@form} id="person-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:dob]} type="date" label="Date of birth" />
        <.input field={@form[:id_number]} type="text" label="ID number" />
        <.input field={@form[:designation]} type="text" label="Designation" />
        <.input field={@form[:role]} type="text" label="Role" />
        <.input field={@form[:residential_address]} type="textarea" label="Residential address" />
        <.input field={@form[:appointment_date]} type="date" label="Appointment date" />
        <.input field={@form[:resignation_date]} type="date" label="Resignation date" />
        <.input
          field={@form[:entity_id]}
          type="select"
          label="Entity"
          prompt="Select an entity"
          options={@entity_options}
        />

        <footer class="mt-4 flex items-center gap-3">
          <.button variant="primary" phx-disable-with="Saving...">Save Person</.button>
          <.button navigate={~p"/people"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    # Build the <select> options once: a list of {label, value} tuples.
    # The label is what the user sees (the UEN), the value is what gets saved (the id).
    entity_options = Enum.map(EntityManagement.list_entities(), &{&1.uen, &1.id})

    {:ok,
     socket
     |> assign(:entity_options, entity_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  # When the route is /people/new, start from a blank %Person{}.
  defp apply_action(socket, :new, _params) do
    person = %Person{}

    socket
    |> assign(:page_title, "New Person")
    |> assign(:person, person)
    |> assign(:form, to_form(PeopleManagement.change_person(person)))
  end

  # When the route is /people/:id/edit, load the existing person from the DB.
  defp apply_action(socket, :edit, %{"id" => id}) do
    person = PeopleManagement.get_person!(id)

    socket
    |> assign(:page_title, "Edit Person")
    |> assign(:person, person)
    |> assign(:form, to_form(PeopleManagement.change_person(person)))
  end

  # Fired on every keystroke/change: re-run the changeset so validation
  # errors appear live, without touching the database.
  @impl true
  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset = PeopleManagement.change_person(socket.assigns.person, person_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  # Fired on submit: branch on whether we are creating or editing.
  def handle_event("save", %{"person" => person_params}, socket) do
    save_person(socket, socket.assigns.live_action, person_params)
  end

  defp save_person(socket, :new, person_params) do
    case PeopleManagement.create_person(person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person created successfully")
         |> push_navigate(to: ~p"/people")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_person(socket, :edit, person_params) do
    case PeopleManagement.update_person(socket.assigns.person, person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person updated successfully")
         |> push_navigate(to: ~p"/people")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
