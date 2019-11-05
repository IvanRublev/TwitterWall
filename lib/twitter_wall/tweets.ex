defmodule TwitterWall.Tweets do
  @moduledoc """
  A collection of Tweets to be displayed struct and functions.
  """
  alias TwitterWall.Tweet

  defstruct all: [], errors: []

  @type t :: %__MODULE__{all: tweet_list, errors: error_list}

  @type tweet_list :: [Tweet.t()]
  @type error_list :: [any] | nil

  @spec new(list :: tweet_list) :: t()
  def new(list), do: %__MODULE__{all: list}

  @spec new(list :: tweet_list, errors :: list) :: t()
  def new(list, errors), do: %__MODULE__{all: list, errors: errors}

  @spec count(tweets :: t()) :: integer
  def count(tweets), do: Enum.count(tweets.all)

  @spec errors(tweets :: t()) :: error_list
  def errors(tweets), do: tweets.errors

  def add(t1, t2) do
    new(t1.all ++ t2.all, t1.errors ++ t2.errors)
  end
end
