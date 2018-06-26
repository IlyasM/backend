defmodule BackendWeb.MainChannel do
  use BackendWeb, :channel
  alias Phoenix.Socket.Broadcast
  @status_updates ["received", "seen"]
  # this channel is created for one user only to intercept notifications from other channels
  # => channel will only push to one single user of user_id any related notifications from other channels
  # it also manages presence for conversation channel
  # it subscribes to events from conversation channel (mainly for various messaging status updates)

  def join("main:" <> user_id, _, socket) do
    if authorized?(user_id, socket) do
      send(self(), :after_join)

      {:ok, state, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    current_user = socket.assigns.current_user

    # track me so other users know whether I am online or not
    BackendWeb.Presence.track(socket, current_user.id, %{
      user: current_user
    })

    # state is a list of {user_id,chat_id} to track all my chats/ refactor to cache
    state = Backend.chat_state_for(user_id)
    assign(socket, :state, state)

    # get all [chats] for the user and subscribe to all conversation:<>{id in [chats]}
    MainChannel.subscribe_all(socket, current_user.id)

    push(socket, "presence_state", BackendWeb.Presence.list(socket))
    {:noreply, socket}
  end

  # this callback intercepts events from our conversation channel thanks to our subcription
  # events will be of kind new:msg, typing, status:received, status:seen
  def handle_info(
        %Broadcast{topic: "conversation:" <> _chat_id, event: ev, payload: payload},
        socket
      ) do
    resp =
      case ev do
        "new:msg" ->
          Backend.create_message(payload["message"])

        "typing" ->
          :ok

        status when status in @status_updates ->
          Backend.update_message_status(payload["message_id"], status)

        some_ev ->
          IO.inspect(some_ev)
          :ok
      end

    push(socket, ev, resp)
    {:noreply, socket}
  end

  def handle_in("new:chat", %{"user_id" => id}, socket) do
    {:ok, chat} = Backend.create_chat(id, socket.assings.current_user.id)

    entry = %{
      chat_id: chat.id,
      u_id: Enum.find(chat.users, &(&1.id == id))
    }

    update(entry, socket)
    push(socket, "new_state", socket.assigns.state)
    # notify the other user of chat creation
    # Backend.Endpoint.broadcast("main:" <> id, "state:update", entry)

    {:reply, :ok, socket}
  end

  # def handle_in("state:update", entry, socket) do
  #   update(entry, socket)
  #   push(socket, "new_state", socket.assigns.state)
  #   {:reply, :ok, socket}
  # end

  # -=-=-=-=-=-=-=-=-=-PRIVATE API
  defp authorized?(user_id, socket) do
    String.to_integer(user_id) == socket.assigns.current_user.id
  end

  # currently topics are of kind conversation:chat_id in this application we don't unsubscribe
  # since we are interested in all related activity of our conversations  when we are not in a conversation channel
  defp subscribe_all(socket, user_id) do
    chat_ids = Backend.chats_for_user(current_user.id)

    topics =
      chat_ids
      |> Enum.map(&("conversation:" <> Integer.to_string(&1)))

    topics
    |> Enum.each(&subcribe(&1, socket))
  end

  defp subscribe(topic, socket) do
    topics = socket.assigns.topics || []

    unless topic in topics do
      :ok = Backend.Endpoint.subscribe(topic)
      assign(socket, :topics, [topic | topics])
    end
  end

  defp update(entry, socket) do
    state = socket.assings.state

    unless entry in state do
      assign(socket, :state, [entry | state])
    end
  end
end

# problem - data structure to track both users i have chat with and the corresponding chat ids
# something like [{user_a, chat_id}, {user_b,chat_id}]
