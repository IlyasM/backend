defmodule BackendWeb.AuthTest do
  use BackendWeb.ConnCase
  use BackendWeb, :db

  @user_params %{
    name: "Ilyas",
    email: "ilyas@c.com",
    password: "1234"
  }

  @invalid_params %{name: "ilyas", email: "bla"}

  test "POST /api/sign_up -- successful registration, unique email", %{conn: conn} do
    conn =
      post(conn, "/api/sign_up", %{
        user: @user_params
      })

    assert %{"message" => _, "ok" => _} = json_response(conn, 200)

    conn =
      post(conn, "/api/sign_up", %{
        user: @user_params
      })

    assert %{
             "errors" => %{
               "email" => ["has already been taken"]
             }
           } = json_response(conn, 401)
  end

  test "POST /api/sign_up -- invalid params",
       %{conn: conn} do
    conn =
      post(conn, "/api/sign_up", %{
        user: @invalid_params
      })

    assert %{
             "errors" => %{
               "email" => _email_errors,
               "password" => _password_error
             }
           } = json_response(conn, 401)
  end

  test "POST /api/sign_in -- token created successfully",
       %{conn: conn} do
    User.registration_changeset(%User{}, @user_params)
    |> Repo.insert!()

    conn =
      post(conn, "/api/sign_in", %{
        session: Map.take(@user_params, [:email, :password])
      })

    assert %{
             "jwt" => _
           } = json_response(conn, 200)
  end

  test "DELETE /api/sign_out -- correctly signs out", %{conn: conn} do
    user =
      User.registration_changeset(%User{}, @user_params)
      |> Repo.insert!()

    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :api)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> jwt)
      |> delete("api/sign_out")

    assert %{"ok" => "you signed out"} = json_response(conn, 200)
  end

  test "POST /api/sign_in -- fails with wrong password or wrong email",
       %{conn: conn} do
    User.registration_changeset(%User{}, @user_params)
    |> Repo.insert!()

    conn =
      post(conn, "/api/sign_in", %{
        session: %{email: @user_params.email, password: "2"}
      })

    assert %{
             "error" => "unauthorized"
           } = json_response(conn, 401)

    conn =
      post(conn, "/api/sign_in", %{
        session: %{email: "ilys@c.com", password: "2"}
      })

    assert %{
             "error" => "not found"
           } = json_response(conn, 401)
  end
end
