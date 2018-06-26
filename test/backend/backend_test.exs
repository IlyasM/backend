defmodule Backend.BackendTest do
  use BackendWeb, :db
  use Backend.DataCase

  setup do
    Backend.DataHelper.users_chat()
  end

  test "correctly creates chat", %{user1: user1, user2: user2} do
    assert {:ok, _} = Backend.create_chat(user1.id, user2.id)
  end

  test "creates message in a chat", %{user1: user1, chat: chat} do
    message = Backend.create_message(%{author_id: user1.id, chat_id: chat.id, text: "hello"})
    assert message.text == "hello"
  end

  test "updates message status", %{user1: user1, chat: chat} do
    message = Backend.create_message(%{author_id: user1.id, chat_id: chat.id, text: "hello"})
    assert message.status == "saved"
    message = Backend.update_message_status(message.id, "received")
    assert message.status == "received"
  end

  test "messages since", %{user1: user1, chat: chat} do
    messages =
      1..10
      |> Enum.map(fn _ ->
        Backend.create_message(%{
          author_id: user1.id,
          chat_id: chat.id,
          text: Enum.random(["hello", "yo", "how is it going", "whats up", "bro"])
        })
      end)

    random_id = Enum.random(messages).id
    [h | _] = Backend.messages_since(chat.id, random_id)
    assert h.id == random_id + 1
  end
end
