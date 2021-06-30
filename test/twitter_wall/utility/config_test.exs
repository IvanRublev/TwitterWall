defmodule TwitterWall.Utility.ConfigTest do
  use ExUnit.Case, async: true

  describe "__using__/1" do
    test "makes module functions to operate on config key given with options" do
      defmodule ApiConfig do
        use TwitterWall.Utility.Config, key: :config_test_env_key
      end

      Application.put_env(:twitter_wall, :config_test_env_key, :app_env_value)
      assert ApiConfig.get(:global) == :app_env_value

      ApiConfig.set(:global, :some_value)
      assert Application.get_env(:twitter_wall, :config_test_env_key) == :some_value

      ApiConfig.set(:process, :other_value)
      assert ApiConfig.get(:process) == :other_value
    after
      Application.delete_env(:twitter_wall, :config_test_env_key)
    end

    test "raises error missing :key option" do
      assert_raise ArgumentError, ":key option with configuration key name is expected.", fn ->
        defmodule ErrorConfig do
          use TwitterWall.Utility.Config
        end
      end
    end
  end

  describe "generic get/1, set/1 and merge/1 functions" do
    defmodule SomeConfig do
      use TwitterWall.Utility.Config, key: :config_test_env_key
    end

    test "operate on process key value store given any key already persisted in process" do
      Process.put(:__config_test_env_key, process_value: true)
      assert SomeConfig.get() == [process_value: true]

      SomeConfig.set(:process, process_value: false)
      assert Process.get(:__config_test_env_key) == [process_value: false]

      assert SomeConfig.merge(:process, another_value: true)
      assert Process.get(:__config_test_env_key) == [process_value: false, another_value: true]
    after
      Process.delete(:__config_test_env_key)
    end

    test "operate on application environment key given no key persisted in process" do
      Application.put_env(:twitter_wall, :config_test_env_key, app_env_value: 1)
      assert SomeConfig.get() == [app_env_value: 1]

      SomeConfig.set(:global, app_env_value: 2)
      assert Application.get_env(:twitter_wall, :config_test_env_key) == [app_env_value: 2]

      assert SomeConfig.merge(:global, another_value: true)
      assert Application.get_env(:twitter_wall, :config_test_env_key) == [app_env_value: 2, another_value: true]
    after
      Application.delete_env(:twitter_wall, :config_test_env_key)
    end
  end
end
