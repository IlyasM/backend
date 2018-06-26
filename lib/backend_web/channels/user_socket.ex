defmodule BackendWeb.UserSocket do
  use Phoenix.Socket
  ## Channels
  channel("conversation:*", BackendWeb.ConversationChannel)
  channel("main:*", BackendWeb.MainChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)
  # transport :longpoll, Phoenix.Transports.LongPoll

  def connect(%{"token" => token}, socket) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Backend.GuardianSerializer.from_token(claims["sub"]) do
      {:ok,
       socket
       |> assign(:topics, [])
       |> assign(:state, [])
       |> assign(:current_user, %{id: user.id, email: user.email, name: user.name})}
    else
      {:error, _reason} -> :error
    end
  end

  def connect(_params, _socket) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     BackendWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.current_user.id}"
end
