defmodule ExCashier do
  @moduledoc """
  Main module for the `ExCashier` app!

  It contains the functions needed to test the application.
  """
  require Logger

  alias ExCashier.{Checkout, UserCart}

  @doc """
  Creates a new user cart process and registers it to the user cart registry.
  """
  @spec create_user_cart(binary()) :: {:ok, pid()} | {:error, {:already_started, pid()}} | :error
  def create_user_cart(user_identifier), do: UserCart.create(user_identifier)

  @doc """
  Adds an item to a user's cart.
  """
  @spec add_item(binary(), binary(), pos_integer()) :: :ok | {:error, :not_found} | :error
  def add_item(user_identifier, item_identifier, quantity \\ 1),
    do: UserCart.add(user_identifier, item_identifier, quantity)

  @doc """
  Returns a user's cart.
  """
  @spec get_user_cart(binary()) ::
          %{user_id: binary(), items: map()} | {:error, :not_found} | :error
  def get_user_cart(user_identifier), do: UserCart.get(user_identifier)

  @doc """
  Returns the amount a user has to pay for its cart.
  """
  @spec checkout(binary()) :: {:ok, float()} | :error
  def checkout(user_identifier), do: Checkout.start(user_identifier)
end
