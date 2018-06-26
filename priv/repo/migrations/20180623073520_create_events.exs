defmodule Backend.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:status, :string)
      add(:text, :string)
      add(:chat_id, references(:chats, on_delete: :delete_all))
      add(:author_id, references(:users, on_delete: :nilify_all))
      timestamps()
    end
  end
end
