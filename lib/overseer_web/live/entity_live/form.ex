defmodule OverseerWeb.EntityLive.Form do
  use OverseerWeb, :live_view

  alias Overseer.Management.EntityManagement
  alias Overseer.Registry.Entity

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:entity}>
      <.header>
        {@page_title}
        <:subtitle>Fields marked required must be filled in.</:subtitle>
      </.header>

      <.form for={@form} id="entity-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:uen]} type="text" label="UEN" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input field={@form[:industry]} type="text" label="Industry" />
        <.input field={@form[:address]} type="text" label="Address" />
        <.input field={@form[:suburb]} type="text" label="Suburb" />
        <.input field={@form[:contact_number]} type="text" label="Contact number" />
        <.input field={@form[:incorporation_date]} type="date" label="Incorporation date" />

        <footer class="mt-4 flex items-center gap-3">
          <.button variant="primary" phx-disable-with="Saving...">Save Entity</.button>
          <.button navigate={~p"/entity"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    entity = %Entity{}

    socket
    |> assign(:page_title, "New Entity")
    |> assign(:entity, entity)
    |> assign(:form, to_form(EntityManagement.change_entity(entity)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    entity = EntityManagement.get_entity!(id)

    socket
    |> assign(:page_title, "Edit Entity")
    |> assign(:entity, entity)
    |> assign(:form, to_form(EntityManagement.change_entity(entity)))
  end

  @impl true
  def handle_event("validate", %{"entity" => entity_params}, socket) do
    changeset = EntityManagement.change_entity(socket.assigns.entity, entity_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"entity" => entity_params}, socket) do
    save_entity(socket, socket.assigns.live_action, entity_params)
  end

  defp save_entity(socket, :new, entity_params) do
    case EntityManagement.create_entity(entity_params) do
      {:ok, _entity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entity created successfully")
         |> push_navigate(to: ~p"/entity")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_entity(socket, :edit, entity_params) do
    case EntityManagement.update_entity(socket.assigns.entity, entity_params) do
      {:ok, _entity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entity updated successfully")
         |> push_navigate(to: ~p"/entity")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
