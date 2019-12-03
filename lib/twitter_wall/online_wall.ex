defmodule TwitterWall.OnlineWall do
  @moduledoc """
  An implementation of twitter wall getting tweets from web.
  """

  alias TwitterWall.Infra.TwitterService
  alias TwitterWall.Tweets

  @behaviour TwitterWall

  @impl true
  def last_liked_or_posted(count, _opts), do: last_liked_or_posted(count)

  @impl true
  def last_liked_or_posted(0), do: {:ok, []}

  @impl true
  def last_liked_or_posted(count) do
    joined =
      Tweets.add(
        TwitterService.liked_tweets(count),
        TwitterService.posted_tweets(count)
      )

    with {:ok, tweets} <- any_tweets(joined, as_result_of_calls: [:liked_tweets, :posted_tweets]),
         last_tweets = sort_by_date_desc_and_take(tweets, count),
         {:ok, htmlized} <- htmlize(last_tweets) do
      {:ok, Enum.map(htmlized.all, &{&1.html, &1.kind})}
    end
  end

  defp any_tweets(%Tweets{} = tweets, as_result_of_calls: funcs) do
    failed_funcs =
      tweets.errors
      |> Enum.filter(&(is_tuple(&1) and tuple_size(&1) > 2))
      |> Enum.map(&elem(&1, 1))
      |> MapSet.new()

    if MapSet.subset?(MapSet.new(funcs), failed_funcs) do
      {:error, tweets.errors}
    else
      {:ok, tweets}
    end
  end

  defp sort_by_date_desc_and_take(%Tweets{all: all}, count) do
    all
    |> Enum.sort_by(& &1.date, fn d1, d2 ->
      case {d1, d2} do
        {_, nil} -> false
        {nil, _} -> false
        {_, _} -> Date.compare(d1, d2) == :gt
      end
    end)
    |> Enum.uniq()
    |> Enum.take(count)
    |> Tweets.new()
  end

  defp htmlize(%Tweets{} = not_htmlized) do
    htmlized = TwitterService.htmlize_tweets(not_htmlized)

    if not Enum.empty?(htmlized.errors) and
         Enum.count(htmlized.errors) == Enum.count(not_htmlized.all) do
      {:error, htmlized.errors}
    else
      {:ok, htmlized}
    end
  end
end
