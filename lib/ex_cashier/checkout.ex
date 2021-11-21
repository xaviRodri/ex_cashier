defmodule ExCashier.Checkout do
  @moduledoc """
  The `Checkout` module is in charge of making checkout price calculations.
  """
  require Logger

  @doc """
  Returns the amount a user has to pay for its cart.

  It will apply all the discounts available.
  """
  @spec start(binary()) :: {:ok, float()}
  def start(user_identifier) when is_binary(user_identifier) do
    case ExCashier.UserCart.get(user_identifier) do
      {:error, :not_found} -> {:error, :not_found}
      %{} = cart -> calculate(cart)
    end
  end

  def start(_user_identifier) do
    Logger.error("User identifiers must be strings")
    :error
  end

  # Returns the checkout price for a user cart.
  defp calculate(cart) do
    checkout_price =
      Enum.map(cart, &calculate_item/1)
      |> Enum.reduce(0, &sum_item_total_price/2)
      |> Float.round(2)

    {:ok, checkout_price}
  end

  # Calculates the checkout price for an specific item.
  defp calculate_item({item_identifier, user_item_attrs}) do
    {_item_identifier, item_attrs} =
      item_identifier
      |> ExCashier.Catalogue.get()

    ExCashier.Checkout.DiscountManager.apply(user_item_attrs, item_attrs)
    |> calculate_original_price(item_attrs)
    |> calculate_item_total_price(item_attrs)
  end

  # Calculates the original price (without discounts) for an item.
  defp calculate_original_price(
         %{quantity: qty} = user_item_attrs,
         %{"price" => original_price}
       ) do
    Map.put(user_item_attrs, :original_price, original_price * qty)
  end

  # Calculates the total price of a item.
  #  Will look for discount or original prices in the user item attrs.
  defp calculate_item_total_price(
         %{discount_price: discount_price} = user_item_attrs,
         _item_attrs
       ) do
    Map.put(user_item_attrs, :total_price, discount_price)
  end

  defp calculate_item_total_price(
         %{original_price: original_price} = user_item_attrs,
         _item_attrs
       ) do
    Map.put(user_item_attrs, :total_price, original_price)
  end

  # Sums the total prices of the cart items to get the total checkout price
  defp sum_item_total_price(%{total_price: total_item_price}, acc) do
    acc + total_item_price
  end
end
