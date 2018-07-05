defmodule BackendWeb.MainChannel do
  use BackendWeb, :channel
  use BackendWeb, :db

  alias Phoenix.Socket.Broadcast

  # main channel will only push to one single user of user_id any related notifications from other channels
  # it subscribes to events from conversation channel (mainly for various messaging updates)
  def join("main:" <> user_id, _, socket) do
    if authorized?(user_id, socket) do
      send(self(), :after_join)

      users = Backend.users(user_id)

      {:ok, %{users: users}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    current_user = socket.assigns.current_user
    # state is a list of {user_id,chat_id} to track all my chats/ refactor to cache
    state = Backend.chat_state_for(current_user.id)

    push(socket, "my_chats", %{state: state})
    {:noreply, socket |> assign(:state, state) |> subscribe_all}
  end

  # this callback handles events from our conversation channel thanks to our subcription
  # events will be of kind new:msg, typing, received, seen
  def handle_info(
        %Broadcast{topic: "conversation:" <> _, event: ev, payload: payload},
        socket
      ) do
    push(socket, ev, payload)

    {:noreply, socket}
  end

  def handle_in("received", %{"message" => message}, socket) do
    message = Backend.update_message_status(message["id"], "received")
    IO.inspect("in main channell received")
    # notify sender that her message is received
    BackendWeb.Endpoint.broadcast_from(
      self(),
      "conversation:" <> Integer.to_string(message.chat_id),
      "received",
      message
    )

    {:noreply, socket}
  end

  def handle_in("new:chat", %{"user_id" => id}, socket) do
    {:ok, chat} = Backend.create_chat(id, socket.assigns.current_user.id)

    entry = %{
      chat_id: chat.id,
      u_id: id
    }

    {:reply, {:ok, entry}, socket}
  end

  # -=-=-=-=-=-=-=-=-=-PRIVATE API
  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end

  # interested in all related activity of our conversations  when we are not in a conversation channel
  defp subscribe_all(socket) do
    socket.assigns.state
    |> Stream.map(& &1.chat_id)
    |> Stream.map(&("conversation:" <> Integer.to_string(&1)))
    |> Enum.reduce(socket, fn topic, acc ->
      topics = acc.assigns.topics

      if topic in topics do
        acc
      else
        :ok = BackendWeb.Endpoint.subscribe(topic)
        assign(acc, :topics, [topic | topics])
      end
    end)
  end
end
