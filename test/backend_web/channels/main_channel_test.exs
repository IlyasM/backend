defmodule BackendWeb.MainChannelTest do
  use BackendWeb.ChannelCase
  use BackendWeb, :db
  import Backend.DataHelper

  setup do
    %{user1: user1, user2: user2, chat: chat} = users_chat()
    {:ok, token1, _full_claims} = Guardian.encode_and_sign(user1, :api)
    {:ok, token2, _full_claims} = Guardian.encode_and_sign(user2, :api)

    {:ok, socket1} = connect(BackendWeb.UserSocket, %{"token" => token1})
    {:ok, socket2} = connect(BackendWeb.UserSocket, %{"token" => token2})

    %{user1: user1, user2: user2, socket1: socket1, socket2: socket2, chat: chat}
  end

  test "join main channel", %{socket1: socket1} do
    assert {:ok, %{}, _} =
             subscribe_and_join(
               socket1,
               "main:#{socket1.assigns.current_user.id}",
               %{}
             )
  end

  test "creates chat", %{socket1: socket1, user2: user2} do
    {:ok, %{}, socket} =
      subscribe_and_join(
        socket1,
        "main:#{socket1.assigns.current_user.id}",
        %{}
      )

    ref =
      push(socket, "new:chat", %{
        "user_id" => user2.id
      })

    assert_reply(ref, :ok, entry)
    assert entry.u_id == user2.id

    # assert_receive %Phoenix.Socket.Message{
    #   topic: _,
    #   event: "new_chat",
    #   payload: entry
    # }
  end

  test "correctly handles subcription", %{
    socket1: socket1,
    socket2: socket2,
    chat: chat
  } do
    user = socket1.assigns.current_user
    # user1 joins main channel
    subscribe_and_join(
      socket1,
      "main:#{user.id}",
      %{}
    )

    topic = "conversation:#{chat.id}"

    # user2 joins second channel
    assert {:ok, %{messages: _}, socket} =
             subscribe_and_join(
               socket2,
               topic,
               %{"last_seen_id" => 0}
             )

    # user 2 pushes new message to conversation channel
    ref =
      push(socket, "new:msg", %{
        "message" => %{"author_id" => user.id, "chat_id" => chat.id, "text" => "yo"}
      })

    # user1 subscribed on main channel catches event
    assert_receive %Phoenix.Socket.Broadcast{
      topic: _,
      event: "new:msg",
      payload: %Message{text: "yo"}
    }

    # user2 also gets a message in reply
    assert_reply(ref, :ok, data)
    assert data.message.text == "yo"
    assert data.message.status == "saved"
  end
end
