defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update,
                                                 :delete]
  plug :check_topic_owner when action in [:update, :edit, :delete]

  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn
    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "You do not have permissions for that action")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end

  def index(conn, _params) do
    topics = Repo.all(from Topic, order_by: [desc: :id])
    render conn, "index.html", topics: topics
  end

  def show(conn, %{"id" => topic_id}) do
    topic = Repo.get!(Topic, topic_id)
    render conn, "show.html", topic: topic
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"topic" => topic}) do
    changeset = Ecto.build_assoc(conn.assigns.user, :topics)
    |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic created")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error creating topic")
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => topic_id}) do
    topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(topic)
    render conn, "edit.html", changeset: changeset, topic: topic
  end

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    existing_topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(existing_topic, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error updating topic")
        |> render("edit.html", changeset: changeset, topic: existing_topic)
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(topic)

    case Repo.delete(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic deleted")
        |> redirect(to: topic_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error deleting topic")
        |> redirect(to: topic_path(conn, :index))
    end
  end

end
