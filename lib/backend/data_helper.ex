defmodule Backend.DataHelper do
  use BackendWeb, :db

  @user_params_1 %{
    name: "Ilyas",
    email: "ilyas@c.com",
    password: "1234"
  }

  @user_params_2 %{
    name: "Timur",
    email: "timur@c.com",
    password: "1234"
  }

  def users_chat do
    user1 =
      User.registration_changeset(%User{}, @user_params_1)
      |> Repo.insert!()

    user2 =
      User.registration_changeset(%User{}, @user_params_2)
      |> Repo.insert!()

    # {:ok, jwt1, _full_claims} = Guardian.encode_and_sign(user1, :api)

    {:ok, chat} = Backend.create_chat(user1.id, user2.id)
    %{user1: user1, user2: user2, chat: chat}
  end

  def user do
    User.registration_changeset(%User{}, @user_params_1)
    |> Repo.insert!()
  end
end
