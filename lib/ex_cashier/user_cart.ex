defmodule ExCashier.UserCart do
  @moduledoc """
  This module defines a user cart process.

  It also contains the needed handlers to operate with it.
  """
  use GenServer

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
end
