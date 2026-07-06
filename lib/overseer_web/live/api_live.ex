defmodule OverseerWeb.ApiLive do
  use OverseerWeb, :live_view

  alias Overseer.Management.EntityManagement
  alias Overseer.PublicApi.BasicInfo
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
          <h3 class="text-sm font-semibold">Serve it on your own domain</h3>

          <p :if={!@custom_domain} class="mt-1 text-sm text-base-content/70">
            Enter a subdomain you own (like <code class="font-mono">api.yourdomain.com</code>)
            and add one DNS record. Your API is then live on your domain — nothing to host.
          </p>

          <.form for={@domain_form} id="custom-domain-form" phx-submit="save_domain" class="mt-3">
            <div class="flex items-end gap-3">
              <div class="grow max-w-md">
                <.input
                  field={@domain_form[:custom_domain]}
                  type="text"
                  label="Custom domain"
                  placeholder="api.yourdomain.com"
                />
              </div>
              <.button variant="primary" phx-disable-with="Saving...">Save</.button>
              <.button :if={@custom_domain} phx-click="remove_domain" type="button">
                Remove
              </.button>
            </div>
          </.form>

          <div :if={@custom_domain} class="mt-4 space-y-3 text-sm">
            <p>Add this record at your DNS provider:</p>
            <pre class="rounded-box bg-base-200 p-4 font-mono text-xs">{@cname_record}</pre>
            <p>Once DNS propagates, your API answers on your domain:</p>
            <ul class="ml-5 list-disc space-y-1 font-mono text-xs">
              <li>https://{@custom_domain}/openapi.json</li>
              <li>https://{@custom_domain}/.well-known/openapi.json</li>
              <li>https://{@custom_domain}/basic-info</li>
            </ul>
            <p class="text-base-content/70">
              HTTPS certificates are provisioned by Overseer after the DNS record is in
              place; allow a few minutes on first setup.
            </p>
          </div>
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

  def handle_event("save_domain", %{"entity" => entity_params}, socket) do
    case EntityManagement.update_custom_domain(socket.assigns.current_entity, entity_params) do
      {:ok, entity} ->
        message =
          if entity.custom_domain,
            do: "Custom domain saved. Add the DNS record below to finish setup.",
            else: "Custom domain removed."

        {:noreply, socket |> assign_api_state() |> put_flash(:info, message)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :domain_form, to_form(changeset))}
    end
  end

  def handle_event("remove_domain", _params, socket) do
    {:ok, _entity} =
      EntityManagement.update_custom_domain(socket.assigns.current_entity, %{
        custom_domain: nil
      })

    {:noreply, socket |> assign_api_state() |> put_flash(:info, "Custom domain removed.")}
  end

  # Reloads the entity so the api_config embed is fresh, then derives
  # everything the page shows from it.
  defp assign_api_state(socket) do
    entity = EntityManagement.get_entity!(socket.assigns.current_entity.id)
    public? = BasicInfo.public?(entity)
    base_url = OverseerWeb.Endpoint.url()
    app_host = OverseerWeb.Endpoint.config(:url)[:host] || "localhost"

    # The preview mirrors what agents will actually fetch: the custom
    # domain when one is set, the canonical URL otherwise.
    server_url =
      if entity.custom_domain,
        do: "https://#{entity.custom_domain}",
        else: "#{base_url}/api/v1/#{entity.uen}"

    assign(socket,
      current_entity: entity,
      basic_info_public: public?,
      custom_domain: entity.custom_domain,
      domain_form: to_form(EntityManagement.change_custom_domain(entity)),
      cname_record: "#{entity.custom_domain || "api.yourdomain.com"}  CNAME  #{app_host}",
      spec_url: "#{base_url}/api/v1/#{entity.uen}/openapi.json",
      basic_info_url: "#{base_url}/api/v1/#{entity.uen}/basic-info",
      spec_json:
        if(public?, do: Jason.encode!(OpenApiSpec.generate(entity, server_url), pretty: true))
    )
  end
end
