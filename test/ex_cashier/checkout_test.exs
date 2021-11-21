defmodule ExCashier.CheckoutTest do
  use ExUnit.Case, async: true
  alias ExCashier.{Checkout, UserCart}
  # This will hide logs in the console when testing
  @moduletag :capture_log

  @valid_user_identifier "1234abcd"
  @invalid_user_identifier %{invalid: "identifier"}
  @item_identifier "GR1"

  describe "start/1" do
    setup do
      {:ok, pid} = ExCashier.create_user_cart(@valid_user_identifier)
      on_exit(fn -> terminate_children(pid) end)
    end

    test "Returns the total checkout price given a cart" do
      :ok = UserCart.add(@valid_user_identifier, @item_identifier)

      assert {:ok, 3.11} = ExCashier.Checkout.start(@valid_user_identifier)
    end

    test "Returns a total price containing discounts if some of the items has one" do
      # Will take an item with a `2x1` discount for this test

      :ok = UserCart.add(@valid_user_identifier, @item_identifier, 2)

      assert {:ok, 3.11} = Checkout.start(@valid_user_identifier)
    end

    test "Returns an error when the user identifier is not valid" do
      assert :error = Checkout.start(@invalid_user_identifier)
    end
  end

  defp terminate_children(pid),
    do: DynamicSupervisor.terminate_child(ExCashier.UserCartSupervisor, pid)
end
