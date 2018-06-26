defmodule BackendWeb.UserSocketTest do
  use BackendWeb.ChannelCase, async: true

  alias BackendWeb.UserSocket

  test "socket authentication with valid token" do
    user = Backend.DataHelper.user()
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :api)
    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.current_user.id == user.id
  end

  test "socket authentication with invalid token" do
    assert :error = connect(UserSocket, %{"token" => "1313"})
    assert :error = connect(UserSocket, %{})
  end
end
