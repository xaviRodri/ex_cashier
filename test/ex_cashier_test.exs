defmodule ExCashierTest do
  use ExUnit.Case, async: true
  # This will hide logs in the console when testing
  @moduletag :capture_log

  @user_identifier "mainuser1234"

  describe "Required tests" do
    setup :create_and_cleanup

    test "Cart: GR1,SR1,GR1,GR1,CF1. Should return a total of 22.45" do
      assert %{} = ExCashier.get_user_cart(@user_identifier)
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "SR1")
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "CF1")

      assert {:ok, 22.45} = ExCashier.checkout(@user_identifier)
    end

    test "Cart: GR1,GR1. Should return a total of 3.11" do
      assert %{} = ExCashier.get_user_cart(@user_identifier)
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "GR1")

      assert {:ok, 3.11} = ExCashier.checkout(@user_identifier)
    end

    test "Cart: SR1,SR1,GR1,SR1. Should return a total of 16.61" do
      assert %{} = ExCashier.get_user_cart(@user_identifier)
      :ok = ExCashier.add_item(@user_identifier, "SR1")
      :ok = ExCashier.add_item(@user_identifier, "SR1")
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "SR1")

      assert {:ok, 16.61} = ExCashier.checkout(@user_identifier)
    end

    test "Cart: GR1,CF1,SR1,CF1,CF1. Should return a total of 30.57" do
      assert %{} = ExCashier.get_user_cart(@user_identifier)
      :ok = ExCashier.add_item(@user_identifier, "GR1")
      :ok = ExCashier.add_item(@user_identifier, "CF1")
      :ok = ExCashier.add_item(@user_identifier, "SR1")
      :ok = ExCashier.add_item(@user_identifier, "CF1")
      :ok = ExCashier.add_item(@user_identifier, "CF1")

      assert {:ok, 30.57} = ExCashier.checkout(@user_identifier)
    end
  end

  describe "remove_item/3" do
    setup :create_and_cleanup

    test "Removes an item from a user's cart" do
      :ok = ExCashier.add_item(@user_identifier, "GR1", 5)
      assert %{"GR1" => %{quantity: 5}} = ExCashier.get_user_cart(@user_identifier)

      assert :ok = ExCashier.remove_item(@user_identifier, "GR1")
      assert %{"GR1" => %{quantity: 4}} = ExCashier.get_user_cart(@user_identifier)
    end
  end

  defp create_and_cleanup(_) do
    {:ok, pid} = ExCashier.create_user_cart(@user_identifier)
    on_exit(fn -> DynamicSupervisor.terminate_child(ExCashier.UserCartSupervisor, pid) end)
  end
end
