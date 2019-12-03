defmodule TwitterWall.Stub do
  @moduledoc """
  An implementation of twitter wall that stubs tweets with generated ones.
  """

  @behaviour TwitterWall

  @impl true
  def last_liked_or_posted(count, _opts), do: last_liked_or_posted(count)

  @impl true
  def last_liked_or_posted(count) do
    {:ok, Enum.map(1..count, fn i -> {"<blockquote>tweet#{i}</blockquote>", tw_kind(i)} end)}
  end

  defp tw_kind(i), do: rem(i, 2) == 0 && :liked || :posted
end
