defmodule OverseerWeb.ApiLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.EntityManagement
  alias Overseer.PublicApi.OpenApiSpec

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "API") |> assign_api_state()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:api} current_entity={@current_entity}>
      <.header>
        API
        <:subtitle>Publish parts of {@current_entity.uen} as a public, machine-readable API.</:subtitle>
      </.header>

      <section class="mt-6 rounded-box border border-base-300 p-6">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h2 class="font-semibold">Basic information</h2>
            <p class="text-sm text-base-content/70">
              Registration details, industry, and contact information.
              No personal data is ever included.
            </p>
          </div>
          <input
            type="checkbox"
            class="toggle toggle-primary"
            checked={@basic_info_public}
            phx-click="toggle_basic_info"
          />
        </div>
      </section>

      <section :if={@basic_info_public} class="mt-6 rounded-box border border-base-300 p-6">
        <h2 class="font-semibold">Your public API is live</h2>

        <div class="mt-4 space-y-2 text-sm">
          <p>
            <span class="font-medium">OpenAPI spec:</span>
            <a href={@spec_url} target="_blank" class="link link-primary font-mono">{@spec_url}</a>
          </p>
          <p>
            <span class="font-medium">Basic info endpoint:</span>
            <a href={@basic_info_url} target="_blank" class="link link-primary font-mono">
              {@basic_info_url}
            </a>
          </p>
        </div>

        <div class="mt-6">
          <h3 class="text-sm font-semibold">Put it on your own domain</h3>
          <p class="mt-1 text-sm text-base-content/70">
            Download the spec and host it at
            <code class="font-mono">https://yourdomain.com/.well-known/openapi.json</code>
            so agents and LLMs visiting your site can discover it. Calls are served by
            Overseer either way. Re-download after changing what you publish.
          </p>
          <.button variant="primary" class="mt-3" href={@spec_url} download="openapi.json">
            <.icon name="hero-arrow-down-tray" class="size-4" /> Download openapi.json
          </.button>
        </div>

        <div class="mt-6">
          <h3 class="text-sm font-semibold">Spec preview</h3>
          <pre class="mt-2 max-h-96 overflow-auto rounded-box bg-base-200 p-4 text-xs"><code>{@spec_json}</code></pre>
        </div>
      </section>

      <p :if={!@basic_info_public} class="mt-4 text-sm text-base-content/70">
        Nothing is published. Turn a section on to generate your public OpenAPI spec.
      </p>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("toggle_basic_info", _params, socket) do
    entity = socket.assigns.current_entity
    publishing? = !socket.assigns.basic_info_public

    {:ok, _entity} =
      EntityManagement.update_api_config(entity, %{basic_info_public: publishing?})

    message =
      if publishing?,
        do: "Basic information is now publicly available.",
        else: "Basic information is no longer published."

    {:noreply, socket |> assign_api_state() |> put_flash(:info, message)}
  end

  # Reloads the entity so the api_config embed is fresh, then derives
  # everything the page shows from it.
  defp assign_api_state(socket) do
    entity = EntityManagement.get_entity!(socket.assigns.current_entity.id)
    public? = Overseer.PublicApi.BasicInfo.public?(entity)
    base_url = OverseerWeb.Endpoint.url()

    assign(socket,
      current_entity: entity,
      basic_info_public: public?,
      spec_url: "#{base_url}/api/v1/#{entity.uen}/openapi.json",
      basic_info_url: "#{base_url}/api/v1/#{entity.uen}/basic-info",
      spec_json:
        if(public?,
          do: Jason.encode!(OpenApiSpec.generate(entity, base_url), pretty: true)
        )
    )
  end
end
