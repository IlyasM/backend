defmodule BackendWeb.RegistrationController do
  use BackendWeb, :controller
  use BackendWeb, :db

  def sign_up(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> json(%{
          ok: "user created",
          message: """
            Now you can sign in using your email and password at /api/sign_in. You will receive JWT token.
            Please put this token into Authorization header for all authorized requests.
          """
        })

      {:error, changeset} ->
        conn
        |> put_status(401)
        |> json(%{
          errors:
            Ecto.Changeset.traverse_errors(changeset, &BackendWeb.ErrorHelpers.translate_error/1)
        })
    end
  end
end
