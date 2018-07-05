defmodule Backend.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset
  use BackendWeb, :db

  @derive {
    Poison.Encoder,
    only: [:id, :status, :text, :author_id, :chat_id, :inserted_at]
  }
  schema "messages" do
    field(:status, :string, default: "saved")
    field(:text, :string)
    belongs_to(:chat, Chat)
    belongs_to(:author, User)

    timestamps()
  end

  @doc false
  # status can be either saved | received | seen
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:status, :text, :author_id, :chat_id])
  end
end
