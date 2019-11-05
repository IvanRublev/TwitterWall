defmodule Cache.Memory do
  @moduledoc """
  An implementation of cache keeping data in memory.
  """
  use GenServer, restart: :transient
  require Logger

  @behaviour TwitterWall.Infra.CacheService

  @impl true
  def start_link(arg) do
    name = Keyword.get(arg, :name, __MODULE__)
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @impl true
  def htmls(name \\ __MODULE__, count, valid_on: date) do
    GenServer.call(name, {:htmls, count, date})
  end

  @impl true
  def put(name \\ __MODULE__, htmls, count, expire_on: date) do
    GenServer.cast(name, {:put, htmls, count, date})
  end

  ### Gen Server
  @impl true
  def init(_init_arg) do
    {:ok, {:empty, %{}}}
  end

  @impl true
  def handle_cast({:put, htmls, count, date}, {_emptiness, count_2_html}) do
    count_2_html = Map.put(count_2_html, count, html: htmls, date: date)

    Logger.debug(
      "#{__MODULE__} #{count} htmls are put with expiration date #{date}, counts htmls cached for: #{
        inspect(Map.keys(count_2_html))
      }"
    )

    {:noreply, {:filled, count_2_html}}
  end

  @impl true
  def handle_call(
        {:htmls, count, date},
        _from,
        {emptiness, count_2_html} = state
      ) do
    content = count_2_html[count]

    status =
      cond do
        emptiness == :empty ->
          :empty

        is_nil(content) ->
          :count_mismatch

        Timex.after?(date, content[:date]) ->
          :expired

        true ->
          {:hit, content[:html]}
      end

    Logger.debug(
      "#{__MODULE__} reply: #{inspect(if is_tuple(status), do: elem(status, 0), else: status)}"
    )

    {:reply, status, state}
  end
end
