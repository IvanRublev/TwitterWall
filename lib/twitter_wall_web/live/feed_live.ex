defmodule TwitterWallWeb.FeedLive do
  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, populate_assigns(socket, 3)}
  end

  defp populate_assigns(socket, count) do
    socket = add_validated_count(socket, count)

    if is_nil(socket.assigns[:input_error]) == false do
      socket
      |> assign(:tweets_html, "")
      |> assign(:general_error, false)
    else
      case TwitterWall.last_liked_or_posted(count) do
        {:ok, htmls} ->
          socket
          |> assign(:tweets_html, Phoenix.HTML.raw(htmls))
          |> assign(:general_error, false)

        {:error, _} ->
          socket
          |> assign(:tweets_html, "")
          |> assign(:general_error, true)
      end
    end
  end

  defp add_validated_count(socket, count) when is_number(count) do
    input_error =
      if count not in 1..10 do
        "Count should be in the 1..10 range. The value is #{count}."
      else
        nil
      end

    socket
      |> assign(:count, count)
      |> assign(:input_error, input_error)
  end

  def render(assigns) do
    ~L"""
    <form action="#" phx-change="ch_count">
    <h1>List of <input type="number" name="tw_count" value="<%= @count %>" id="header_tw_count"/> liked and posted tweets by <a href="https://twitter.com/LevviBraun">LevviBraun</a></h1>
    </form>

    <%= if @general_error do %>
      <div>Can't show anything. Connection to Twitter is Fuzzy today 🤪</div>
    <% end %>
    <%= if @input_error do %>
      <p class="alert alert-danger" role="alert"><%= @input_error %></p>
    <% end %>
    <div id="feed" phx-hook="RerenderTweets">
      <%= @tweets_html %>
    </div>

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
    """
  end

  def handle_event("ch_count", %{"tw_count" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("ch_count", %{"tw_count" => count}, socket) do
    count = String.to_integer(count)
    {:noreply, populate_assigns(socket, count)}
  end
end
