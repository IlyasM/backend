defmodule BackendWeb.ConversationChannel do
  use BackendWeb, :channel
  @empty %{}
  @status_updates ["received", "seen"]

  def join("conversation:" <> chat_id, %{"last_seen_id" => id}, socket) do
    messages = Backend.messages_since(chat_id, id)
    {:ok, %{messages: messages}, socket}
  end

  def handle_in("new:msg", %{"message" => params}, socket) do
    message = Backend.create_message(params)
    broadcast_from!(socket, "new:msg", message)
    {:reply, {:ok, %{message: message}}, socket}
  end

  def handle_in("typing", _params, socket) do
    broadcast_from!(socket, "typing", @empty)
    {:reply, :ok, socket}
  end

  def handle_in(status, %{"message_id" => id}, socket)
      when status in @status_updates do
    message = Backend.update_message_status(id, status)
    broadcast_from!(socket, status, %{message: message})
    {:reply, {:ok, %{message: message}}, socket}
  end
end
