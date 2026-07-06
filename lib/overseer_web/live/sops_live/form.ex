defmodule OverseerWeb.SopsLive.Form do
  use OverseerWeb, :live_view

  alias Overseer.Management.SopManagement
  alias Overseer.Registry.Sop

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:sops} current_entity={@current_entity}>
      <.header>
        {@page_title}
        <:subtitle>Fields marked required must be filled in.</:subtitle>
      </.header>

      <.form for={@form} id="sop-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input
          field={@form[:content]}
          type="textarea"
          label="Content"
          rows="14"
          placeholder="Write the procedure here..."
        />

        <footer class="mt-4 flex items-center gap-3">
          <.button variant="primary" phx-disable-with="Saving...">Save SOP</.button>
          <.button navigate={~p"/#{@current_entity.uen}/sops"}>Cancel</.button>
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
    sop = %Sop{}

    socket
    |> assign(:page_title, "New SOP")
    |> assign(:sop, sop)
    |> assign(:form, to_form(SopManagement.change_sop(sop)))
  end

  # Scoped to the current entity so ids from other entities 404.
  defp apply_action(socket, :edit, %{"id" => id}) do
    sop = SopManagement.get_sop!(socket.assigns.current_entity.id, id)

    socket
    |> assign(:page_title, "Edit SOP")
    |> assign(:sop, sop)
    |> assign(:form, to_form(SopManagement.change_sop(sop)))
  end

  @impl true
  def handle_event("validate", %{"sop" => sop_params}, socket) do
    changeset = SopManagement.change_sop(socket.assigns.sop, sop_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"sop" => sop_params}, socket) do
    save_sop(socket, socket.assigns.live_action, put_entity_id(sop_params, socket))
  end

  # The entity comes from the URL scope, not the form.
  defp put_entity_id(sop_params, socket) do
    Map.put(sop_params, "entity_id", socket.assigns.current_entity.id)
  end

  defp save_sop(socket, :new, sop_params) do
    case SopManagement.create_sop(sop_params) do
      {:ok, _sop} ->
        {:noreply,
         socket
         |> put_flash(:info, "SOP created successfully")
         |> push_navigate(to: ~p"/#{socket.assigns.current_entity.uen}/sops")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_sop(socket, :edit, sop_params) do
    case SopManagement.update_sop(socket.assigns.sop, sop_params) do
      {:ok, _sop} ->
        {:noreply,
         socket
         |> put_flash(:info, "SOP updated successfully")
         |> push_navigate(to: ~p"/#{socket.assigns.current_entity.uen}/sops")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
