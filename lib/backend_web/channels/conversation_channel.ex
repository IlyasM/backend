defmodule BackendWeb.ConversationChannel do
  use BackendWeb, :channel
  @status_updates ["received", "seen"]

  def join("conversation:" <> chat_id, %{"last_seen_id" => id}, socket) do
    send(self(), :after_join)
    messages = Backend.messages_since(chat_id, socket.assigns.current_user.id, id)

    {:ok, %{messages: messages}, socket |> assign(:current_chat, chat_id)}
  end

  def handle_info(:after_join, socket) do
    BackendWeb.Presence.track(socket, socket.assigns.current_user.id, %{
      user: socket.assigns.current_user
    })

    push(socket, "presence_state", BackendWeb.Presence.list(socket))

    broadcast_from!(socket, "seen", %{
      chat_id: socket.assigns.current_chat,
      author_id: socket.assigns.current_user.id,
      on_enter: true
    })

    {:noreply, socket}
  end

  def handle_in("new:msg", %{"message" => params}, socket) do
    message = Backend.create_message(params)

    broadcast_from!(socket, "new:msg", message)
    {:reply, {:ok, %{message: message}}, socket}
  end

  def handle_in("typing", %{"user_id" => user_id}, socket) do
    broadcast_from!(
      socket,
      "typing",
      %{
        chat_id: socket.assigns.current_chat,
        user_id: user_id
      }
    )

    {:reply, :ok, socket}
  end

  def handle_in(status, %{"message_id" => id}, socket)
      when status in @status_updates do

    message = Backend.update_message_status(id, status)
    broadcast_from!(socket, status, message)
    {:reply, :ok, socket}
  end
end
