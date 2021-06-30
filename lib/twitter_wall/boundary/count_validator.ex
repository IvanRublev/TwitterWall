defmodule TwitterWall.Boundary.CountValidator do
  @moduledoc """
  Safely casts a value to integer.
  """

  @expected_range 1..10

  @doc """
  Parses binary value into integer and validates range

  ## Examples

      iex> alias TwitterWall.Boundary.CountValidator
      ...> CountValidator.validate("")
      {:error, value: "", expected_range: 1..10}
      iex> CountValidator.validate("5")
      {:ok, 5}
      iex> CountValidator.validate("hello world")
      {:error, value: "hello world", expected_range: 1..10}
      iex> CountValidator.validate("587hello")
      {:error, value: "587hello", expected_range: 1..10}
      iex> CountValidator.validate("0")
      {:error, value: 0, expected_range: 1..10}
      iex> CountValidator.validate("11")
      {:error, value: 11, expected_range: 1..10}

  """
  def validate(count_string) do
    with {:ok, count} <- parse_integer(count_string),
         {:ok, _count} = ok <- validate_range(count) do
      ok
    else
      {:error, _attrs} = error -> error
    end
  end

  defp parse_integer(count_string) do
    case Integer.parse(count_string) do
      {count, ""} -> build_ok(count)
      {_count, _} -> build_error(count_string)
      :error -> build_error(count_string)
    end
  end

  defp validate_range(count) do
    if count in @expected_range do
      build_ok(count)
    else
      build_error(count)
    end
  end

  defp build_ok(value), do: {:ok, value}

  defp build_error(value), do: {:error, value: value, expected_range: @expected_range}
end
