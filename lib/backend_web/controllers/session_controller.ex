defmodule BackendWeb.SessionController do
  use BackendWeb, :controller
  use BackendWeb, :db

  def sign_in(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case User.find_and_confirm_password(email, password) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :api)

        conn
        |> json(%{user: user, jwt: jwt})

      {:error, reason} ->
        conn
        |> put_status(401)
        |> json(%{error: show(reason)})
    end
  end

  def sign_out(conn, _) do
    jwt = Guardian.Plug.current_token(conn)
    Guardian.revoke!(jwt)

    json(conn, %{ok: "you signed out"})
  end

  defp show(input) do
    case input do
      :unauthorized -> "unauthorized"
      :not_found -> "not found"
    end
  end
end
