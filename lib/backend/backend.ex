defmodule Backend do
  use BackendWeb, :db
  import Ecto.Changeset
  import Ecto.Query

  # -=-=-=-=-=-=-=-=-=-=-=-=-=-=- PUBLIC
  def create_chat(other_id, my_id) do
    Repo.transaction(fn ->
      # check whether we already have a chat
      state = chat_state_for(my_id)

      ids =
        state
        |> Enum.map(& &1.u_id)

      if other_id in ids do
        %{chat_id: chat_id} = Enum.find(state, &(&1.u_id == other_id))
        Repo.get(Chat, chat_id)
      else
        %Chat{}
        |> change()
        |> put_assoc(:users, Repo.all(by_ids(User, [other_id, my_id])))
        |> Repo.insert!()
      end
    end)
  end

  # accepts params with %{text, author_id, chat_id} returns {ok,message} | {error, changeset}
  def create_message(params) do
    Message.changeset(%Message{}, params)
    |> Repo.insert!()
  end

  def update_message_status(message_id, status) do
    message = Repo.get(Message, message_id)
    Repo.update!(change(message, %{status: status}))
  end

  def users(user_id) do
    Repo.all(User)
    |> Enum.reduce(%{}, fn user, acc ->
      if String.to_integer(user_id) == user.id do
        acc
      else
        Map.put(acc, user.id, user)
      end
    end)
  end

  def chats_for_user(user_id) do
    from(c in UserChat, where: c.user_id == ^user_id)
    |> Repo.all()
    |> Enum.map(& &1.chat_id)
  end

  def chat_state_for(user_id) do
    {:ok, state} =
      Repo.transaction(fn ->
        ids = chats_for_user(user_id)

        Repo.all(from(uc in UserChat, where: uc.chat_id in ^ids))
        |> Enum.map(
          &%{
            u_id: &1.user_id,
            chat_id: &1.chat_id,
            message: last_message_for_chat(&1.chat_id),
            unseen_count: unseen_count(&1.chat_id, user_id)
          }
        )
        |> Enum.filter(&(&1.u_id != user_id))
      end)

    state
  end

  def messages_since(chat_id, my_id, last_seen_id \\ 0) do
    from(
      m in Message,
      where: m.chat_id == ^chat_id,
      where: m.author_id != ^my_id,
      where: m.status != "seen",
      update: [set: [status: "seen"]]
    )
    |> Repo.update_all([])

    from(
      m in Message,
      where: m.chat_id == ^chat_id,
      where: m.id > ^last_seen_id,
      order_by: m.id
    )
    |> Repo.all()
  end

  # -=-=-=-=-=-=-=-=-=-=-=-=-=-=- PRIVATE
  defp by_ids(table, ids) do
    from(entry in table, where: entry.id in ^ids)
  end

  defp last_message_for_chat(chat_id) do
    case from(m in Message, where: m.chat_id == ^chat_id) |> last |> Repo.one() do
      nil -> %{text: "start writing", id: -1}
      m -> m
    end
  end

  defp unseen_count(chat_id, my_id) do
    from(
      m in Message,
      where: m.chat_id == ^chat_id,
      where: m.author_id != ^my_id,
      where: m.status != "seen",
      select: count(m.id)
    )
    |> Repo.one()
  end
end
