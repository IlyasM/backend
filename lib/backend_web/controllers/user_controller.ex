defmodule BackendWeb.UserController do
  use BackendWeb, :controller
  use BackendWeb, :db

  def index(conn, _) do
    users = Repo.all(User)
    json(conn, %{users: users})
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    json(conn, %{user: user})
  end
end
