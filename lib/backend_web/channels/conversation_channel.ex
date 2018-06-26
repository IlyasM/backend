defmodule BackendWeb.ConversationChannel do
  use BackendWeb, :channel
  @empty %{}
  @status_updates ["received", "seen"]

  def join("conversation:" <> chat_id, %{"last_seen_id" => id}, socket) do
    send(self(), :after_join)
    messages = Backend.messages_since(chat_id, id)

    # need to start sending
    {:ok, %{messages: messages}, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "joined", %{joined: true})
    {:noreply, socket}
  end

  def handle_in("new:msg", %{"message" => params}, socket) do
    message = Backend.create_message(params)
    broadcast_from!(socket, "new:msg", message)
    {:reply, :ok, socket}
  end

  def handle_in("typing", params, socket) do
    broadcast_from!(socket, "typing", @empty)
    {:reply, :ok, socket}
  end

  def handle_in(status, %{"message_id" => id}, socket)
      when status in @status_updates do
    message = Backend.update_message_status(id, status)
    broadcast_from!(socket, "status:" <> status, %{message: message})
    {:reply, :ok, socket}
  end
end
