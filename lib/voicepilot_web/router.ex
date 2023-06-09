defmodule VoicepilotWeb.Router do
  use VoicepilotWeb, :router

  import VoicepilotWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {VoicepilotWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", VoicepilotWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  # Other scopes may use custom stacks.
  # scope "/api", VoicepilotWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:voicepilot, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: VoicepilotWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", VoicepilotWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{VoicepilotWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", VoicepilotWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{VoicepilotWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)

      live("/voices", VoiceLive.Index, :index)
      live("/voices/new", VoiceLive.Index, :new)
      live("/voices/:id/edit", VoiceLive.Index, :edit)
      live("/voices/:id", VoiceLive.Show, :show)
      live("/voices/:id/show/edit", VoiceLive.Show, :edit)

      live("/sites/new", SiteLive.Index, :new)
      live("/sites/:id/edit", SiteLive.Index, :edit)
      live("/sites/:id/show/edit", SiteLive.Show, :edit)

      live("/sitelists/new", SiteListLive.Index, :new)
      live("/sitelists/:id/edit", SiteListLive.Index, :edit)
      live("/sitelists/:id/show/edit", SiteListLive.Show, :edit)
    end
  end

  scope "/", VoicepilotWeb do
    post("/tts_callback", PageController, :tts_callback)
    get("/tts_callback", PageController, :tts_callback)
  end

  scope "/", VoicepilotWeb do
    pipe_through([:browser])

    live("/sites", SiteLive.Index, :index)
    live("/sites/:id", SiteLive.Show, :show)

    live("/sitelists", SiteListLive.Index, :index)
    live("/sitelists/:id", SiteListLive.Show, :show)

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{VoicepilotWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
