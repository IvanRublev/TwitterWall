defmodule TwitterAPIMocker do
  @moduledoc """
  Helpers to mock Twitter API requests responses
  """
  import Tesla.Mock

  @api_base Application.fetch_env!(:twitter_wall, :twitter_api_1_1_base)
  @publish_base Application.fetch_env!(:twitter_wall, :twitter_publish_base)

  @type request_attrs_fun :: fun(%{query: map(), headers: map()})

  @spec mock_user_timeline_request(response :: request_attrs_fun) :: nil
  def mock_user_timeline_request(response) do
    mock(fn %{url: "#{@api_base}/statuses/user_timeline.json"} = req ->
      wrap(response, passing_attributes: req)
    end)
  end

  @spec mock_favorites_list_request(response :: request_attrs_fun) :: nil
  def mock_favorites_list_request(response) do
    mock(fn %{url: "#{@api_base}/favorites/list.json"} = req ->
      wrap(response, passing_attributes: req)
    end)
  end

  @spec mock_oembed_requests(%{required(String.t()) => request_attrs_fun}) :: nil
  def mock_oembed_requests(map) do
    mock(fn %{url: "#{@publish_base}/oembed"} = req ->
      wrap(map[req.query[:url]], passing_attributes: req)
    end)
  end

  @spec mock_oembed_request(response :: request_attrs_fun) :: nil
  def mock_oembed_request(response) do
    mock(fn %{url: "#{@publish_base}/oembed"} = req ->
      wrap(response, passing_attributes: req)
    end)
  end

  defp wrap(response, passing_attributes: req) do
    req
    |> mapify_attributes()
    |> response.()
    |> json_or_text()
  end

  defp mapify_attributes(req) do
    %{
      query: Enum.into(req.query, %{}),
      headers: Enum.into(req.headers, %{})
    }
  end

  defp json_or_text(r_val) do
    cond do
      is_integer(r_val) ->
        %Tesla.Env{status: r_val}

      is_map(r_val) or is_list(r_val) ->
        json(r_val)

      is_binary(r_val) ->
        text(r_val)

      true ->
        case r_val do
          {status, body} when is_integer(status) and is_binary(body) ->
            %Tesla.Env{status: status, body: body}

          _ ->
            ""
        end
    end
  end
end
