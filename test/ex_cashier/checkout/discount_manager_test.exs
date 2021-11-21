defmodule ExCashier.Checkout.DiscountManagerTest do
  use ExUnit.Case
  # This will hide logs in the console when testing
  @moduletag :capture_log

  import ExUnit.CaptureLog
  require Logger

  @item_identifier "GR1"
  @item_with_discount %{"name" => "Green tea", "price" => 3.11, "discount" => %{"type" => "2x1"}}
  @item_without_discount %{"name" => "Green tea", "price" => 3.11}
  @item_with_discount_not_supported %{
    "name" => "Green tea",
    "price" => 3.11,
    "discount" => %{"type" => "not_supported"}
  }
  @user_identifier "user1234"

  describe "apply/2" do
    setup :create_and_cleanup

    test "Applies discount to the user's item" do
      :ok = ExCashier.UserCart.add(@user_identifier, @item_identifier, 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)[@item_identifier]

      assert %{discount_price: 6.22, quantity: 4} =
               ExCashier.Checkout.DiscountManager.apply(user_item_attrs, @item_with_discount)
    end

    test "Returns the same user item attributes when no discounts available (and logs it)" do
      :ok = ExCashier.UserCart.add(@user_identifier, @item_identifier, 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)[@item_identifier]

      assert capture_log(fn ->
               assert ExCashier.Checkout.DiscountManager.apply(
                        user_item_attrs,
                        @item_without_discount
                      ) == user_item_attrs
             end) =~ "No discounts applicable"
    end

    test "Will not apply any non supported discounts (will log it)" do
      :ok = ExCashier.UserCart.add(@user_identifier, @item_identifier, 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)[@item_identifier]

      assert capture_log(fn ->
               assert ExCashier.Checkout.DiscountManager.apply(
                        user_item_attrs,
                        @item_with_discount_not_supported
                      ) == user_item_attrs
             end) =~ "not supported"
    end
  end

  describe "2x1 discount" do
    setup :create_and_cleanup

    test "Applies a 2x1 discount" do
      :ok = ExCashier.UserCart.add(@user_identifier, @item_identifier, 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)[@item_identifier]

      assert %{discount_price: 6.22, quantity: 4} =
               ExCashier.Checkout.DiscountManager.apply(user_item_attrs, @item_with_discount)
    end
  end

  describe "Exact drop price discount" do
    setup :create_and_cleanup

    test "Applies an exact drop price discount" do
      :ok = ExCashier.UserCart.add(@user_identifier, "SR1", 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)["SR1"]
      {_item_id, item_attrs} = ExCashier.Catalogue.get("SR1")

      assert %{discount_price: 18.0, quantity: 4} =
               ExCashier.Checkout.DiscountManager.apply(user_item_attrs, item_attrs)
    end
  end

  describe "% drop price discount" do
    setup :create_and_cleanup

    test "Applies a % drop price discount" do
      :ok = ExCashier.UserCart.add(@user_identifier, "CF1", 4)
      user_item_attrs = ExCashier.UserCart.get(@user_identifier)["CF1"]
      {_item_id, item_attrs} = ExCashier.Catalogue.get("CF1")

      assert %{discount_price: 29.948164000000002, quantity: 4} =
               ExCashier.Checkout.DiscountManager.apply(user_item_attrs, item_attrs)
    end
  end

  defp create_and_cleanup(_) do
    {:ok, pid} = ExCashier.create_user_cart(@user_identifier)
    on_exit(fn -> DynamicSupervisor.terminate_child(ExCashier.UserCartSupervisor, pid) end)
  end
end
