defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug Ueberauth

  alias Discuss.User

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{token: auth.credentials.token, email: auth.info.email,
                    provider: Atom.to_string(auth.provider)}

    changeset = User.changeset(%User{}, user_params)

    signin(conn, changeset)
  end

  def signout(conn, _params) do
    conn
    |> clear_session
    |> put_flash(:info, "User signed out")
    |> redirect(to: topic_path(conn, :index))
  end

  defp signin(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User signed in")
        |> put_session(:user_id, user.id)
        |> redirect(to: topic_path(conn, :index))
      {:error, %{errors: _errors}} ->
        # IO.puts "+++++"
        # IO.inspect errors
        # IO.puts "+++++"
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  defp insert_or_update_user(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        IO.puts "+++++ No user found, trying to insert"
        Repo.insert(changeset)
      user ->
        IO.puts "+++++ User found, trying to update record"
        %{changes: changes} = changeset
        Repo.update(User.changeset(user, changes))
    end
  end
end
