defmodule OverseerWeb.Router do
  use OverseerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OverseerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OverseerWeb do
    pipe_through :browser

    live "/", EntityLive, :index
    live "/entity/new", EntityLive.Form, :new

    # Routes scoped to a single entity, identified by its UEN.
    # EntityScope resolves the UEN and assigns :current_entity.
    live_session :entity_scope, on_mount: OverseerWeb.EntityScope do
      live "/:uen/home", HomeLive, :home
      live "/:uen/settings", EntityLive.Form, :edit
      live "/:uen/people", PeopleLive, :index
      live "/:uen/people/new", PeopleLive.Form, :new
      live "/:uen/people/:id/edit", PeopleLive.Form, :edit
      live "/:uen/partners", PartnersLive, :index
      live "/:uen/assets", AssetsLive, :index
      live "/:uen/assets/new", AssetsLive.Form, :new
      live "/:uen/assets/:id/edit", AssetsLive.Form, :edit
      live "/:uen/map", MapLive, :index
      live "/:uen/sops", SopsLive, :index
      live "/:uen/sops/new", SopsLive.Form, :new
      live "/:uen/sops/:id/edit", SopsLive.Form, :edit
      live "/:uen/assistant", AssistantLive, :index
      live "/:uen/integrations", IntegrationsLive, :index
      live "/:uen/api", ApiLive, :index
      live "/:uen/mcp", McpLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", OverseerWeb do
  #   pipe_through :api
  # end

  scope "/mcp" do
    forward "/", EMCP.Transport.StreamableHTTP, server: Overseer.MCPServer
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:overseer, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OverseerWeb.Telemetry
    end
  end
end
