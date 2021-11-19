defmodule ExCashier do
  @moduledoc """
  Main module for the `ExCashier` app!

  It contains the functions needed to test the application.
  """
  require Logger

  alias ExCashier.{UserCart, UserCartRegistry, UserCartSupervisor}

  @doc """
  Starts a new user cart process and registers it to the user cart registry.
  """
  @spec start_user_cart(binary()) :: {:ok, pid()} | {:error, {:already_started, pid()}} | :error
  def start_user_cart(user_identifier) when is_binary(user_identifier) do
    registry_name = {:via, Registry, {UserCartRegistry, user_identifier}}

    DynamicSupervisor.start_child(UserCartSupervisor, {UserCart, name: registry_name})
  end

  def start_user_cart(_user_identifier) do
    Logger.error("User identifiers must be strings")
    :error
  end

  @doc """
  Adds an item to the user's cart.
  """
  @spec add_item(binary(), binary()) :: :ok | {:error, :not_found} | :error
  def add_item(user_identifier, item_identifier)
      when is_binary(user_identifier) and is_binary(item_identifier) do
    case lookup_user_cart(user_identifier) do
      {:ok, pid} ->
        Logger.info("Added item #{item_identifier} to user #{user_identifier}.")
        GenServer.cast(pid, {:add_item, item_identifier})

      {:error, :not_found} ->
        Logger.error("User #{user_identifier} not found.")
        {:error, :not_found}
    end
  end

  def add_item(_user_identifier, _item_identifier) do
    Logger.error("User and item identifiers must be strings")
    :error
  end

  @doc """
  Returns a user's cart.
  """
  @spec get_user_cart(binary()) ::
          %{user_id: binary(), items: map()} | {:error, :not_found} | :error
  def get_user_cart(user_identifier) when is_binary(user_identifier) do
    case lookup_user_cart(user_identifier) do
      {:ok, pid} -> GenServer.call(pid, :get_cart)
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def get_user_cart(_user_identifier) do
    Logger.error("User and item identifiers must be strings")
    :error
  end

  # Returns the PID of a user's cart.
  @spec lookup_user_cart(binary()) :: {:ok, pid()} | {:error, :not_found} | :error
  defp lookup_user_cart(user_identifier) when is_binary(user_identifier) do
    case Registry.lookup(ExCashier.UserCartRegistry, user_identifier) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  defp lookup_user_cart(_user_identifier) do
    Logger.error("User identifiers must be strings")
    :error
  end
end
