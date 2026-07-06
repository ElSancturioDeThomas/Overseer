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

    live "/", HomeLive, :home
    live "/entity", EntityLive, :index
    live "/entity/new", EntityLive.Form, :new
    live "/entity/:id/edit", EntityLive.Form, :edit
    live "/people", PeopleLive, :index
    live "/people/new", PeopleLive.Form, :new
    live "/people/:id/edit", PeopleLive.Form, :edit
    live "/partners", PartnersLive, :index
    live "/assets", AssetsLive, :index
    live "/assets/new", AssetsLive.Form, :new
    live "/assets/:id/edit", AssetsLive.Form, :edit
    live "/map", MapLive, :index
    live "/assistant", AssistantLive, :index
    live "/integrations", IntegrationsLive, :index
    live "/api", ApiLive, :index
    live "/mcp", McpLive, :index
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
