defmodule ExternalResource do
  @moduledoc """
  Implement the macro to load external resource and add @external_resource attribute.
  """

  defmacro decode_external_json(path, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :external_resource, unquote(path))
      unquote(path) |> File.read!() |> Jason.decode!(unquote(opts))
    end
  end

  defmacro read_external_file(path) do
    quote do
      Module.put_attribute(__MODULE__, :external_resource, unquote(path))
      unquote(path) |> File.read!()
    end
  end
end
