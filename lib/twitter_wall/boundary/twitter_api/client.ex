defmodule TwitterWall.Boundary.TwitterAPI.Client do
  @moduledoc """
  Module to call API
  """

  alias TwitterWall.Utility.URIBuilder

  def get_request(url, query_params \\ [], headers \\ [], body \\ nil) do
    url = URIBuilder.uri_string_by_appending_query(url, query_params)

    :get
    |> Finch.build(url, headers, body)
    |> Finch.request(TwitterAPI)
  end

  def validate_status_code(_ok_error, _ok_statuses \\ [200])

  def validate_status_code({:ok, response} = ok, ok_statuses) do
    if Enum.member?(ok_statuses, response.status) do
      ok
    else
      {:error, response}
    end
  end

  def validate_status_code({:error, _message} = error, _ok_statuses) do
    error
  end

  def decode_json_response(_response, _opts \\ [])

  def decode_json_response({:ok, %{body: body}}, opts) do
    case Jason.decode(body, opts) do
      {:ok, parsed_body} ->
        {:ok, parsed_body}

      {:error, message} ->
        {:error, message}
    end
  end

  def decode_json_response({:error, _message} = error, _opts) do
    error
  end

  def get_field(_response, _field, _default \\ nil)

  def get_field({:ok, map}, field, default) do
    {:ok, Map.get(map, field, default)}
  end

  def get_field({:error, _message} = error, _field, _default) do
    error
  end
end
