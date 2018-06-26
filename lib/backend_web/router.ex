defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
    plug(Guardian.Plug.LoadResource, allow_blank: true)
  end

  pipeline :authenticated do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  scope "/", BackendWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  # Other scopes may use custom stacks.
  scope "/api", BackendWeb do
    pipe_through(:api)

    post("/sign_up", RegistrationController, :sign_up)
    post("/sign_in", SessionController, :sign_in)
    # restrict unauthenticated access for routes below
    pipe_through(:authenticated)
    resources("/users", UserController, except: [:new, :edit])
    delete("/sign_out", SessionController, :sign_out)
  end
end
