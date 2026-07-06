defmodule OverseerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use OverseerWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  attr(:active_tab, :atom,
    default: nil,
    doc: "which sidebar nav item is currently active, e.g. :entity"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <aside class="flex w-60 shrink-0 flex-col border-r border-base-300 bg-base-200">
        <a href={~p"/"} class="flex h-16 items-center gap-2 border-b border-base-300 px-4">
          <img src={~p"/images/logo.svg"} width="28" />
          <span class="text-lg font-semibold">Overseer</span>
        </a>

        <nav class="flex-1 p-3">
          <ul class="menu w-full gap-1">
            <li class="menu-title">Company</li>
            <.nav_link navigate={~p"/"} icon="hero-home" active={@active_tab == :home}>
              Home
            </.nav_link>
            <.nav_link navigate={~p"/entity"} icon="hero-building-office-2" active={@active_tab == :entity}>
              Entity
            </.nav_link>
            <.nav_link navigate={~p"/people"} icon="hero-users" active={@active_tab == :people}>
              People
            </.nav_link>
            <.nav_link navigate={~p"/partners"} icon="hero-building-storefront" active={@active_tab == :partners}>
              Partners
            </.nav_link>
            <.nav_link navigate={~p"/assets"} icon="hero-banknotes" active={@active_tab == :assets}>
              Assets
            </.nav_link>
            <.nav_link navigate={~p"/map"} icon="hero-map" active={@active_tab == :map}>
              Map
            </.nav_link>
            <.nav_link navigate={~p"/assistant"} icon="hero-sparkles" active={@active_tab == :assistant}>
              Assistant
            </.nav_link>

            <li class="menu-title">Connect</li>
            <.nav_link navigate={~p"/integrations"} icon="hero-link" active={@active_tab == :integrations}>
              Integrations
            </.nav_link>
            <.nav_link navigate={~p"/api"} icon="hero-code-bracket" active={@active_tab == :api}>
              API
            </.nav_link>
            <.nav_link navigate={~p"/mcp"} icon="hero-cube" active={@active_tab == :mcp}>
              MCP
            </.nav_link>
          </ul>
        </nav>
      </aside>

      <div class="flex flex-1 flex-col">
        <header class="navbar border-b border-base-300 px-4 sm:px-6 lg:px-8">
          <div class="flex-1"></div>
          <div class="flex-none">
            <.theme_toggle />
          </div>
        </header>

        <main class="flex-1 px-4 py-10 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-6xl space-y-4">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  # Renders a single sidebar navigation link.
  # Used inside the sidebar `<ul class="menu">` in `app/1`.
  attr(:navigate, :string, required: true, doc: "the route to navigate to")
  attr(:icon, :string, required: true, doc: "a heroicon name, e.g. \"hero-users\"")
  attr(:active, :boolean, default: false, doc: "whether this is the current page")
  slot(:inner_block, required: true)

  defp nav_link(assigns) do
    ~H"""
    <li>
      <.link navigate={@navigate} class={["flex items-center gap-3", @active && "menu-active font-medium"]}>
        <.icon name={@icon} class="size-5" />
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
