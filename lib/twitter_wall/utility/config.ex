defmodule TwitterWall.Utility.Config do
  @moduledoc """
  Module to get configuration from process or application
  """

  defmacro __using__(opts) do
    application_key = opts[:key]
    if is_nil(application_key), do: raise(ArgumentError, ":key option with configuration key name is expected.")
    process_key = String.to_atom("__#{Atom.to_string(application_key)}")

    quote do
      @application_key unquote(application_key)
      @process_key unquote(process_key)

      def current_scope do
        if Process.get(@process_key), do: :process, else: :global
      end

      def get, do: get(current_scope())

      def get(:global) do
        Application.get_env(:twitter_wall, @application_key)
      end

      def get(:process), do: Process.get(@process_key)

      def set(:global, value) do
        Application.put_env(:twitter_wall, @application_key, value)
      end

      def set(:process, value) do
        Process.put(@process_key, value)
        :ok
      end

      def merge(:global, value) do
        Application.put_env(:twitter_wall, @application_key, Keyword.merge(get() || [], value))
      end

      def merge(:process, value) do
        Process.put(@process_key, Keyword.merge(get() || [], value))
        :ok
      end
    end
  end
end
