defmodule HtmlGetters do
  @moduledoc false

  def get_tag(html, selector) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find(selector)
  end

  def get_attribute(html, attribute) do
    html
    |> Floki.parse_fragment!()
    |> Floki.attribute(attribute)
  end

  def get_child_texts(html, selector \\ nil) do
    html
    |> Floki.parse_fragment!()
    |> then(&if selector, do: Floki.find(&1, selector), else: &1)
    |> List.first()
    |> cast_list()
    |> Floki.children()
    |> cast_list()
    |> Enum.map(&Floki.text/1)
  end

  defp cast_list(nil), do: []
  defp cast_list(list), do: list
end
