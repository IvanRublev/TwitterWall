defmodule TwitterWall.Tweet do
  @moduledoc """
  A Tweet struct.
  """
  defstruct [:id, :date, :html, :kind]

  @type t :: %__MODULE__{
          id: String.t(),
          date: Date.t(),
          html: String.t(),
          kind: atom()
        }
end
