defmodule OverseerWeb.AssetsLive.Form do
  use OverseerWeb, :live_view

  alias Overseer.Management.AssetManagement
  alias Overseer.Management.EntityManagement
  alias Overseer.Registry.Asset

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:assets}>
      <.header>
        {@page_title}
        <:subtitle>Fields marked required must be filled in.</:subtitle>
      </.header>

      <.form for={@form} id="asset-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:code]} type="text" label="Code" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input field={@form[:value]} type="number" label="Value" step="0.01" />
        <.input field={@form[:acquisition_date]} type="date" label="Acquisition date" />
        <.input
          field={@form[:entity_id]}
          type="select"
          label="Entity"
          prompt="Select an entity"
          options={@entity_options}
        />

        <footer class="mt-4 flex items-center gap-3">
          <.button variant="primary" phx-disable-with="Saving...">Save Asset</.button>
          <.button navigate={~p"/assets"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    entity_options = Enum.map(EntityManagement.list_entities(), &{&1.uen, &1.id})

    {:ok,
     socket
     |> assign(:entity_options, entity_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    asset = %Asset{}

    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, asset)
    |> assign(:form, to_form(AssetManagement.change_asset(asset)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    asset = AssetManagement.get_asset!(id)

    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, asset)
    |> assign(:form, to_form(AssetManagement.change_asset(asset)))
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset = AssetManagement.change_asset(socket.assigns.asset, asset_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.live_action, asset_params)
  end

  defp save_asset(socket, :new, asset_params) do
    case AssetManagement.create_asset(asset_params) do
      {:ok, _asset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Asset created successfully")
         |> push_navigate(to: ~p"/assets")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_asset(socket, :edit, asset_params) do
    case AssetManagement.update_asset(socket.assigns.asset, asset_params) do
      {:ok, _asset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Asset updated successfully")
         |> push_navigate(to: ~p"/assets")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
