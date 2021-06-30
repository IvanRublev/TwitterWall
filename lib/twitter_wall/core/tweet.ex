defmodule TwitterWall.Core.Tweet do
  @moduledoc """
  A Tweet struct.
  """

  @enforce_keys [:id, :date, :html, :kind]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: String.t(),
          date: Date.t(),
          html: String.t(),
          kind: :liked | :posted
        }

  @doc """
  Constructs new tweet instance

  ## Examples

      iex> alias TwitterWall.Core.Tweet
      ...> Tweet.new(id: "id", date: ~D[2021-06-27], html: "html", kind: :liked)
      %Tweet{id: "id", date: ~D[2021-06-27], html: "html", kind: :liked}

  """
  def new(fields \\ []), do: struct!(__MODULE__, fields)
end
