defmodule TwitterWall.Infra.CacheService.Stub do
  @moduledoc """
  An implementation of Cache that returns empty cache.
  """
  @behaviour TwitterWall.Infra.CacheService

  @impl true
  def start_link(_arg), do: :ignore

  @impl true
  def htmls(_count, valid_on: _date), do: :empty

  @impl true
  def put(_htmls, _count, expire_on: _date), do: :ok
end
