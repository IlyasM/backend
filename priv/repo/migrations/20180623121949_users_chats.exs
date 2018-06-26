defmodule Backend.Repo.Migrations.UsersChats do
  use Ecto.Migration

  def change do
    create table(:users_chats) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:chat_id, references(:chats, on_delete: :delete_all))

      timestamps()
    end

    create(index(:users_chats, [:user_id]))
    create(index(:users_chats, [:chat_id]))
  end
end
