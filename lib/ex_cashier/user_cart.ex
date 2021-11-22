defmodule ExCashier.UserCart do
  @moduledoc """
  This module defines a user cart process.

  It also contains the needed handlers to operate with it.
  """
  use GenServer
  require Logger
  alias ExCashier.{UserCart, UserCartRegistry, UserCartSupervisor}

  ########
  ## API
  ########

  @doc """
  Creates a new user cart process and registers it to the user cart registry.
  """
  @spec create(binary()) :: {:ok, pid()} | {:error, {:already_started, pid()}} | :error
  def create(user_identifier) when is_binary(user_identifier) do
    registry_name = {:via, Registry, {UserCartRegistry, user_identifier}}
    DynamicSupervisor.start_child(UserCartSupervisor, {UserCart, name: registry_name})
  end

  def create(_user_identifier) do
    Logger.error("User identifiers must be strings")
    :error
  end

  @doc """
  Returns the user's cart.
  """
  @spec get(binary()) :: %{user_id: binary(), items: map()} | {:error, :not_found} | :error
  def get(user_identifier) when is_binary(user_identifier) do
    case lookup_user_cart(user_identifier) do
      {:ok, pid} -> GenServer.call(pid, :get_cart)
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def get(_user_identifier) do
    Logger.error("User identifiers must be strings")
    :error
  end

  @doc """
  Adds an item to the user's cart.
  """
  @spec add(binary(), binary(), pos_integer()) :: :ok | {:error, :not_found} | :error
  def add(user_identifier, item_identifier, qty \\ 1)

  def add(user_identifier, item_identifier, qty)
      when is_binary(user_identifier) and is_binary(item_identifier) and is_integer(qty) and
             qty > 0 do
    with true <- ExCashier.Catalogue.exist?(item_identifier),
         {:ok, pid} <- lookup_user_cart(user_identifier) do
      Logger.debug("Added #{qty} item(s) #{item_identifier} to user #{user_identifier}.")
      GenServer.cast(pid, {:add_item, item_identifier, qty})
    else
      false ->
        Logger.error("Item #{item_identifier} not found in the catalogue.")
        {:error, :item_not_found}

      {:error, :not_found} ->
        Logger.error("User #{user_identifier} not found.")
        {:error, :not_found}
    end
  end

  def add(_user_identifier, _item_identifier, _qty) do
    Logger.error(
      "User and item identifiers must be strings, and quantity must be a positive integer"
    )

    :error
  end

  @doc """
  Removes an item or reduces its quantity from the user's cart.
  """
  @spec remove(binary(), binary(), pos_integer() | :all) :: :ok | {:error, :not_found} | :error
  def remove(user_identifier, item_identifier, qty \\ 1)

  def remove(user_identifier, item_identifier, qty)
      when is_binary(user_identifier) and is_binary(item_identifier) and
             (is_integer(qty) or qty == :all) and
             qty > 0 do
    with true <- ExCashier.Catalogue.exist?(item_identifier),
         {:ok, pid} <- lookup_user_cart(user_identifier) do
      GenServer.cast(pid, {:remove_item, item_identifier, qty})
    else
      false ->
        Logger.error("Item #{item_identifier} not found in the catalogue.")
        {:error, :item_not_found}

      {:error, :not_found} ->
        Logger.error("User #{user_identifier} not found.")
        {:error, :not_found}
    end
  end

  def remove(_user_identifier, _item_identifier, _qty) do
    Logger.error(
      "User and item identifiers must be strings, and quantity must be a positive integer or the atom `:all`"
    )

    :error
  end

  # Returns the PID of a user's cart.
  @spec lookup_user_cart(binary()) :: {:ok, pid()} | {:error, :not_found}
  defp lookup_user_cart(user_identifier) do
    case Registry.lookup(ExCashier.UserCartRegistry, user_identifier) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  ###########
  ## SERVER
  ###########

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{user_id: nil, items: %{}}}
  end

  @impl true
  def handle_call(:get_cart, _from, state) do
    {:reply, state.items, state}
  end

  @impl true
  def handle_cast({:add_item, item_id, qty}, state) do
    {:noreply, %{state | items: add_item(state.items, item_id, qty)}}
  end

  @impl true
  def handle_cast({:remove_item, item_id, qty}, state) do
    {:noreply, %{state | items: remove_item(state.items, item_id, qty)}}
  end

  # Adds an new item to the current item list (with quantity 1)
  # or updates the current quantity of it (sums 1)
  defp add_item(items_map, new_item, qty) do
    case Map.get(items_map, new_item) do
      nil ->
        Map.put(items_map, new_item, %{quantity: qty})

      %{quantity: prev_qty} = item ->
        Map.put(items_map, new_item, %{item | quantity: prev_qty + qty})
    end
  end

  # Removes an item or reduces its quantity from the current item list
  defp remove_item(items_map, item_id, qty) do
    case Map.get(items_map, item_id) do
      nil ->
        IO.inspect("HEY")
        Logger.error("Item #{item_id} not present in the cart. Can not remove it.")
        items_map

      %{quantity: _prev_qty} when qty == :all ->
        Map.delete(items_map, item_id)

      %{quantity: prev_qty} when qty >= prev_qty ->
        Map.delete(items_map, item_id)

      %{quantity: prev_qty} = item when qty < prev_qty ->
        Map.put(items_map, item_id, %{item | quantity: prev_qty - qty})
    end
  end
end
