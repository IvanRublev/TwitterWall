defmodule TwitterWallWeb.FeedLive do
  @moduledoc false

  use TwitterWallWeb, :live_view

  alias TwitterWall.Config

  @impl true
  def render(assigns) do
    ~L"""
    <script>window.twttr = (function(d, s, id) {
      var js, fjs = d.getElementsByTagName(s)[0],
        t = window.twttr || {};
      if (d.getElementById(id)) return t;
      js = d.createElement(s);
      js.id = id;
      js.src = "https://platform.twitter.com/widgets.js";
      fjs.parentNode.insertBefore(js, fjs);

      t._e = [];
      t.ready = function(f) {
        t._e.push(f);
      };

      return t;
    }(document, "script", "twitter-wjs"));</script>

    <form action="#" phx-change="change_count">
      <h1>List of <input type="number" name="count" value="<%= @count %>" id="header_tw_count"/> liked and posted tweets by&nbsp;<%= link @user, to: "https://twitter.com/#{@user}" %></h1>
    </form>

    <%= if assigns[:error] do %>
      <p class="alert alert-danger" role="alert" id="error"><%= @error %></p>
    <% end %>

    <div id="feed" phx-hook="RerenderTweets">
      <%= for tweet <- @tweets_list do %>
        <div class="tw_box"><div class="tw_<%= Atom.to_string(tweet.kind) %>"></div><%= raw(tweet.html) %></div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    config = session["config"] || Config.get()
    user = Keyword.fetch!(config, :screen_name)
    count = Keyword.fetch!(config, :default_tweet_count)

    task = get_tweets(count)

    {:ok,
     socket
     |> assign(user: user)
     |> assign(count: count)
     |> assign(tweets_list: [])
     |> assign(get_tweets_task: task)}
  end

  defp get_tweets(previous_task \\ nil, count) do
    if previous_task do
      Task.shutdown(previous_task, :brutal_kill)
    end

    Task.async(fn -> TwitterWall.get_tweets(count) end)
  end

  @impl true
  def handle_event("change_count", %{"count" => count_string}, socket) do
    socket =
      case TwitterWall.validate_count(count_string) do
        {:ok, count} ->
          socket
          |> assign(:count, count)
          |> assign(:get_tweets_task, get_tweets(socket.assigns[:get_tweets_task], count))

        {:error, attrs} ->
          assign(socket, error: build_input_error_message(attrs))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, aggregate}, %{assigns: %{get_tweets_task: %Task{ref: ref}}} = socket) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(tweets_list: aggregate.tweets)
     |> assign(error: build_api_error(aggregate.errors))}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp build_input_error_message(attrs) do
    """
    Count should be an integer in the #{inspect(attrs[:expected_range])} range. \
    Given value is #{inspect(attrs[:value])}.\
    """
  end

  defp build_api_error([]), do: nil
  defp build_api_error([_ | _]), do: "Output is limited. Connection to Twitter is Fuzzy today 🤪"
end
