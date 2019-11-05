use Distillery.Releases.Config

defmodule Env do
  @moduledoc false
  def cookie(), do: System.get_env("COOKIE") |> String.to_atom
end

environment :dev do
  set cookie: Env.cookie()
end

environment :prod do
  set cookie: Env.cookie()
end
