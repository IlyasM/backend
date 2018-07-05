defmodule Backend.Messaging.User do
  Faker.start()
  use Ecto.Schema
  import Ecto.Changeset
  use BackendWeb, :db
  @derive {Poison.Encoder, only: [:id, :name, :email, :image]}
  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:image, :string)

    many_to_many(
      :chats,
      Chat,
      join_through: UserChat
    )

    has_many(:messages, Message, foreign_key: :author_id)

    timestamps()
  end

  @doc false
  def registration_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name, :password, :image])
    |> validate_required([:email, :name, :password])
    |> validate_changeset
  end

  defp validate_changeset(struct) do
    struct
    |> validate_length(:email, min: 5, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> generate_password_hash
  end

  defp generate_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  # for login check
  def find_and_confirm_password(email, password) do
    case Backend.Repo.get_by(__MODULE__, email: email) do
      nil ->
        {:error, :not_found}

      user ->
        if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end
    end
  end
end
