defmodule Integer.Parse do
  @moduledoc """
  Safely casts a value to integer.
  """

  @doc """
  Parses value if it's binary or bypasses otherwise.
  """
  def safe(val) do
    if is_binary(val) do
      case Integer.parse(val) do
        {int_val, _} -> {:ok, int_val}
        _ -> {:error, :int_parse_failed}
      end
    else
      {:ok, val}
    end
  end
end
