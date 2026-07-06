defmodule OverseerWeb.EntityLive.Form do
  use OverseerWeb, :live_view

  alias Overseer.Management.EntityManagement
  alias Overseer.Registry.Entity

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      sidebar={@live_action == :edit}
      active_tab={:settings}
      current_entity={@current_entity}
    >
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
          <.button navigate={cancel_path(@current_entity)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  # /entity/new is global: there is no entity yet, so no scope or sidebar.
  defp apply_action(socket, :new, _params) do
    entity = %Entity{}

    socket
    |> assign(:page_title, "New Entity")
    |> assign(:current_entity, nil)
    |> assign(:entity, entity)
    |> assign(:form, to_form(EntityManagement.change_entity(entity)))
  end

  # /:uen/settings is scoped: EntityScope already resolved the UEN into
  # :current_entity, so the form edits that record directly.
  defp apply_action(socket, :edit, _params) do
    entity = socket.assigns.current_entity

    socket
    |> assign(:page_title, "Settings")
    |> assign(:entity, entity)
    |> assign(:form, to_form(EntityManagement.change_entity(entity)))
  end

  defp cancel_path(nil), do: ~p"/"
  defp cancel_path(entity), do: ~p"/#{entity.uen}/home"

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
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_entity(socket, :edit, entity_params) do
    case EntityManagement.update_entity(socket.assigns.entity, entity_params) do
      {:ok, entity} ->
        # Use the saved entity's UEN in case it was just changed.
        {:noreply,
         socket
         |> put_flash(:info, "Entity updated successfully")
         |> push_navigate(to: ~p"/#{entity.uen}/home")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
