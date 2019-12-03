defmodule Twitter do
  @moduledoc """
  An implementation of Twitter interface to Twitter webservice.
  """
  alias TwitterWall.Infra.TwitterService
  alias Twitter.ApiJ1M1
  alias Twitter.PublishApi
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet

  @behaviour TwitterService
  @tweet_base_uri Application.fetch_env!(:twitter_wall, :tweet_base_url)

  @impl true
  def liked_tweets(count) do
    {tweets, errors} =
      case ApiJ1M1.favorites(count) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          {body |> list_tweets_date_id() |> apply_kind(:liked), []}

        {_, err} ->
          {[], [traceable_error(__ENV__.function, err)]}
      end

    Tweets.new(tweets, errors)
  end

  defp list_tweets_date_id(body) do
    Enum.map(body, fn
      %{"id" => id, "created_at" => created_at} ->
        date = Timex.parse!(created_at, "{WDshort} {Mshort} {D} {h24}:{m}:{s} {Z} {YYYY}")
        %Tweet{id: id, date: date}

      _ ->
        nil
    end)
  end

  defp apply_kind(list, kind) do
    Enum.map(list, &(!is_nil(&1) && %Tweet{&1 | kind: kind}))
  end

  defp traceable_error(func, err) do
    {__MODULE__, elem(func, 0), err}
  end

  @impl true
  def posted_tweets(count) do
    {tweets, errors} =
      case ApiJ1M1.user_timeline(count) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          {body |> list_tweets_date_id() |> apply_kind(:posted), []}

        {_, err} ->
          {[], [traceable_error(__ENV__.function, err)]}
      end

    Tweets.new(tweets, errors)
  end

  @impl true
  def htmlize_tweets(%Tweets{} = tweets) do
    {tweets, errors} =
      tweets.all
      |> Enum.map(fn %Tweet{id: id} = tw ->
        case PublishApi.oembed("#{@tweet_base_uri}/#{id}") do
          {:ok, %Tesla.Env{status: 200, body: %{"html" => html}}} ->
            {%Tweet{tw | html: html}, nil}

          {_, err} ->
            {nil, traceable_error(__ENV__.function, err)}
        end
      end)
      |> Enum.unzip()

    tweets = Enum.reject(tweets, &is_nil(&1))
    errors = Enum.reject(errors, &is_nil(&1))

    Tweets.new(tweets, errors)
  end
end
