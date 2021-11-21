defmodule ExCashierTest do
  use ExUnit.Case, async: true
  # This will hide logs in the console when testing
  @moduletag :capture_log

  describe "Required tests" do
    setup :clean_up_carts

    test "Cart: GR1,SR1,GR1,GR1,CF1. Should return a total of 22.45" do
      user_identifier = user_identifier()
      {:ok, _pid} = ExCashier.create_user_cart(user_identifier)
      assert %{} = ExCashier.get_user_cart(user_identifier)
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "SR1")
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "CF1")

      assert {:ok, 22.45} = ExCashier.checkout(user_identifier)
    end

    test "Cart: GR1,GR1. Should return a total of 3.11" do
      user_identifier = user_identifier()
      {:ok, _pid} = ExCashier.create_user_cart(user_identifier)
      assert %{} = ExCashier.get_user_cart(user_identifier)
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "GR1")

      assert {:ok, 3.11} = ExCashier.checkout(user_identifier)
    end

    test "Cart: SR1,SR1,GR1,SR1. Should return a total of 16.61" do
      user_identifier = user_identifier()
      {:ok, _pid} = ExCashier.create_user_cart(user_identifier)
      assert %{} = ExCashier.get_user_cart(user_identifier)
      :ok = ExCashier.add_item(user_identifier, "SR1")
      :ok = ExCashier.add_item(user_identifier, "SR1")
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "SR1")

      assert {:ok, 16.61} = ExCashier.checkout(user_identifier)
    end

    test "Cart: GR1,CF1,SR1,CF1,CF1. Should return a total of 30.57" do
      user_identifier = user_identifier()
      {:ok, _pid} = ExCashier.create_user_cart(user_identifier)
      assert %{} = ExCashier.get_user_cart(user_identifier)
      :ok = ExCashier.add_item(user_identifier, "GR1")
      :ok = ExCashier.add_item(user_identifier, "CF1")
      :ok = ExCashier.add_item(user_identifier, "SR1")
      :ok = ExCashier.add_item(user_identifier, "CF1")
      :ok = ExCashier.add_item(user_identifier, "CF1")

      assert {:ok, 30.57} = ExCashier.checkout(user_identifier)
    end
  end

  defp clean_up_carts(_) do
    on_exit(fn ->
      DynamicSupervisor.which_children(ExCashier.UserCartSupervisor)
      |> Enum.map(&terminate_children(&1))
    end)
  end

  defp terminate_children({_, pid, :worker, [ExCashier.UserCart]}),
    do: DynamicSupervisor.terminate_child(ExCashier.UserCartSupervisor, pid)

  defp user_identifier, do: :rand.uniform(100_000) |> to_string()
end
