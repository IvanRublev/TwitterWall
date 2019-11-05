defmodule Cache.MemoryContractTest do
  use ExUnit.Case, async: true
  alias Cache.Memory

  describe "Cache.Memory should" do
    setup ctx do
      {:ok, pid} = Memory.start_link(name: ctx.test)
      {:ok, %{pid: pid}}
    end

    test "be empty after start_link", %{pid: pid} do
      assert Memory.htmls(pid, 3, valid_on: DateTime.utc_now()) == :empty
    end

    test "return :count_mismatch if contains less htmls then requested", %{pid: pid} do
      Memory.put(pid, [], 2, expire_on: ~U[3000-01-01 01:18:35Z])

      assert Memory.htmls(pid, 3, valid_on: DateTime.utc_now()) == :count_mismatch
    end

    test "return :expired if content date is earlier then one requested for htmls", %{pid: pid} do
      Memory.put(pid, [], 2, expire_on: ~U[2000-01-01 01:25:35Z])

      assert Memory.htmls(pid, 2, valid_on: ~U[2000-01-01 01:25:36Z]) == :expired
    end

    test "return :hit and content on request of equal count and date earlier then expiration one",
         %{pid: pid} do
      Memory.put(pid, ["1", "2"], 2, expire_on: ~U[2019-10-12 01:25:35Z])

      assert Memory.htmls(pid, 2, valid_on: ~U[2019-10-12 01:20:00Z]) == {:hit, ["1", "2"]}
    end

    test "store content for different counts simultaneously", %{pid: pid} do
      Memory.put(pid, ["1", "2"], 2, expire_on: ~U[2019-10-12 01:25:35Z])
      Memory.put(pid, ["1", "2", "3"], 3, expire_on: ~U[2019-10-12 01:25:35Z])

      assert Memory.htmls(pid, 2, valid_on: ~U[2019-10-12 01:20:00Z]) == {:hit, ["1", "2"]}
      assert Memory.htmls(pid, 3, valid_on: ~U[2019-10-12 01:20:00Z]) == {:hit, ["1", "2", "3"]}
    end
  end
end
