defmodule TwitterWall.Utility.URIBuilder do
  @moduledoc "Utilities to build URIs"

  @doc """
  Appends path to existing URI

  ## Examples

      iex> alias TwitterWall.Utility.URIBuilder
      ...> URIBuilder.uri_string_by_appending_path("http://test.com", "/some_path")
      "http://test.com/some_path"
      iex> URIBuilder.uri_string_by_appending_path("http://test.com:8080/", "/some_path")
      "http://test.com:8080/some_path"
      iex> URIBuilder.uri_string_by_appending_path("https://test.com/part", "some_path")
      "https://test.com/part/some_path"

  """
  def uri_string_by_appending_path(uri_string, path) do
    base_uri = URI.parse(uri_string)

    joined_path =
      [base_uri.path, path]
      |> Enum.reject(&is_nil/1)
      |> Path.join()

    base_uri
    |> URI.merge(joined_path)
    |> URI.to_string()
  end

  @doc """
  Appends params to existing URI

  ## Examples

      iex> alias TwitterWall.Utility.URIBuilder
      ...> URIBuilder.uri_string_by_appending_query("http://test.com/path", %{one: "1"})
      "http://test.com/path?one=1"
      iex> URIBuilder.uri_string_by_appending_query("http://test.com?super=one", %{one: "1"})
      "http://test.com?one=1&super=one"

  """
  def uri_string_by_appending_query(uri_string, query) do
    base_uri = URI.parse(uri_string)
    joined_query = Map.merge(URI.decode_query(base_uri.query || ""), query)
    encoded_query = URI.encode_query(joined_query)

    base_uri
    |> URI.merge(%URI{query: encoded_query})
    |> URI.to_string()
  end
end
