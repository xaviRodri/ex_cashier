defmodule ExCashier.CheckoutTest do
  use ExUnit.Case
  alias ExCashier.{Checkout, UserCart}
  # This will hide logs in the console when testing
  @moduletag :capture_log

  @valid_user_identifier "1234abcd"
  @invalid_user_identifier %{invalid: "identifier"}
  @item_identifier "GR1"
  describe "start/1" do
    setup :clean_up_carts

    test "Returns the total checkout price given a cart" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      :ok = UserCart.add(@valid_user_identifier, @item_identifier)

      assert {:ok, 3.11} = ExCashier.Checkout.start(@valid_user_identifier)
    end

    test "Returns a total price containing discounts if some of the items has one" do
      # Will take an item with a `2x1` discount for this test

      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      :ok = UserCart.add(@valid_user_identifier, @item_identifier, 2)

      assert {:ok, 3.11} = Checkout.start(@valid_user_identifier)
    end

    test "Returns an error when the user identifier is not valid" do
      assert :error = Checkout.start(@invalid_user_identifier)
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
end
