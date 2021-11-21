defmodule ExCashier.Checkout.DiscountManager do
  @moduledoc """
  The `DiscountManager` module knows all the discounts available
  for the platform and is able to apply them to an item.
  """
  require Logger

  @doc """
  Applies the item discount for an item in a user's cart.

  If a discount is available, it will return the user item attributes modified with
  the `discount price`.
  Otherwise, it will return the same user item attributes received.
  """
  @spec apply(map(), map()) :: map()
  def apply(user_item_attrs, %{"discount" => _discount} = item_attrs) do
    apply_discount(user_item_attrs, item_attrs)
  end

  def apply(user_item_attrs, %{"name" => item_name}) do
    Logger.debug("No discounts applicable to the item #{item_name}.")
    user_item_attrs
  end

  # Applies a `2x1` discount to an item.
  defp apply_discount(
         %{quantity: qty} = user_item_attrs,
         %{"price" => original_price, "discount" => %{"type" => "2x1"}}
       )
       when qty >= 2 do
    Map.put(user_item_attrs, :discount_price, (div(qty, 2) + rem(qty, 2)) * original_price)
  end

  defp apply_discount(user_item_attrs, %{"discount" => %{"type" => "2x1"}}), do: user_item_attrs

  # Applies a fixed drop price to an item.
  defp apply_discount(
         %{quantity: qty} = user_item_attrs,
         %{
           "discount" => %{
             "type" => "drop_price",
             "min_qty" => min_qty,
             "mod_type" => "price",
             "mod" => price_mod
           }
         }
       )
       when qty >= min_qty do
    Map.put(user_item_attrs, :discount_price, price_mod * qty)
  end

  # Applies a % drop price to an item.
  defp apply_discount(
         %{quantity: qty} = user_item_attrs,
         %{
           "price" => original_price,
           "discount" => %{
             "type" => "drop_price",
             "min_qty" => min_qty,
             "mod_type" => "%",
             "mod" => price_mod
           }
         }
       )
       when qty >= min_qty do
    Map.put(user_item_attrs, :discount_price, original_price * (100 - price_mod) / 100 * qty)
  end

  # Will log a discount not supported by the system
  defp apply_discount(user_item_attrs, %{"discount" => discount} = _item_attrs) do
    Logger.warning("Discount #{inspect(discount)} not supported by the system.")
    user_item_attrs
  end
end
