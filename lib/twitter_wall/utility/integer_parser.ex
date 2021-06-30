defmodule TwitterWall.Utility.IntegerParser do
  @moduledoc false

  def parse_integer_safe(val) do
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
