defmodule TwitterWall.Core.TweetAggregate do
  @moduledoc """
  Aggregate of TweetAggregate to be displayed.

    ## Examples

      iex> alias TwitterWall.Core.TweetAggregate
      ...> alias TwitterWall.Core.Tweet
      ...> t1 = Tweet.new(id: "id", date: ~D[2021-06-27], html: "html", kind: :liked)
      ...> TweetAggregate.new(tweets: [t1])
      %TweetAggregate{tweets: [t1], errors: []}
      iex> aggregate1 = TweetAggregate.new(tweets: [t1, t1], errors: [:some_error])
      %TweetAggregate{tweets: [t1, t1], errors: [:some_error]}
      iex> t2 = Tweet.new(id: "id2", date: ~D[2021-06-28], html: "html 1", kind: :liked)
      ...> aggregate2 = TweetAggregate.new(tweets: [t2], errors: [:other_error])
      ...> TweetAggregate.concat(aggregate1, aggregate2)
      %TweetAggregate{tweets: [t1, t1, t2], errors: [:some_error, :other_error]}
      iex> TweetAggregate.update_tweets(aggregate1, &Enum.uniq/1)
      %TweetAggregate{tweets: [t1], errors: [:some_error]}
      iex> TweetAggregate.update_fields(aggregate1, fn fields -> [tweets: Enum.uniq(fields[:tweets]), errors: List.insert_at(fields[:errors], -1, :new_error)] end)
      %TweetAggregate{tweets: [t1], errors: [:some_error, :new_error]}

  """
  alias TwitterWall.Core.Tweet

  defstruct tweets: [], errors: []

  @type t :: %__MODULE__{tweets: [Tweet.t()], errors: [any]}

  def new(fields), do: struct!(__MODULE__, fields)

  def concat(%__MODULE__{} = lhs, %__MODULE__{} = rhs) do
    new(tweets: lhs.tweets ++ rhs.tweets, errors: lhs.errors ++ rhs.errors)
  end

  def update_tweets(%__MODULE__{} = aggregate, fun) do
    updated_tweets = fun.(aggregate.tweets)
    %{aggregate | tweets: updated_tweets}
  end

  def update_fields(%__MODULE__{} = aggregate, fun) do
    aggregate
    |> Map.from_struct()
    |> fun.()
    |> new()
  end
end
