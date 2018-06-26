defmodule BackendWeb.Presence do
  use Phoenix.Presence,
    otp_app: :typi,
    pubsub_server: Typi.PubSub
end
