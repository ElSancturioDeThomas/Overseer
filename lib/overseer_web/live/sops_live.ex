defmodule OverseerWeb.SopsLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.SopManagement

  @impl true
  def mount(_params, _session, socket) do
    sops = SopManagement.list_sops_for_entity(socket.assigns.current_entity.id)

    {:ok, assign(socket, page_title: "SOPs", sops: sops)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:sops} current_entity={@current_entity}>
      <.header>
        SOPs
        <:subtitle>Standard operating procedures for {@current_entity.uen}.</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/#{@current_entity.uen}/sops/new"}>
            <.icon name="hero-plus" class="size-4" /> New SOP
          </.button>
        </:actions>
      </.header>

      <.table id="sops" rows={@sops}>
        <:col :let={sop} label="Title">{sop.title}</:col>
        <:col :let={sop} label="Content">{preview(sop.content)}</:col>
        <:col :let={sop} label="Updated">{Calendar.strftime(sop.updated_at, "%Y-%m-%d")}</:col>
        <:action :let={sop}>
          <.link navigate={~p"/#{@current_entity.uen}/sops/#{sop.id}/edit"} class="link link-primary">
            Edit
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  # Keeps table rows readable when the SOP body is long.
  defp preview(nil), do: ""

  defp preview(content) do
    content
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 80)
    |> then(&if String.length(content) > 80, do: &1 <> "…", else: &1)
  end
end
