defmodule ExCashier.Catalogue do
  @moduledoc """
  This module defines the item catalogue.

  It starts an ETS table that will load and store all the
  catalogue items.
  """
  use GenServer
  require Logger

  @catalogue_path Application.compile_env(:ex_cashier, :catalogue_path)

  ########
  ## API
  ########

  @doc """
  Returns all the items from the item catalogue.
  """
  @spec all() :: list(tuple())
  def all, do: GenServer.call(__MODULE__, :get_all)

  @doc """
  Returns an item from the item catalogue given its identifier.
  """
  @spec get(binary()) :: {binary(), map()} | nil
  def get(item_identifier),
    do: GenServer.call(__MODULE__, {:get_item, item_identifier})

  ###########
  ## SERVER
  ###########

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    {:ok, :ets.new(:catalogue, [:set, :private]), {:continue, :load_catalogue}}
  end

  @impl true
  def handle_continue(:load_catalogue, items_table) do
    with {:ok, body} <- File.read(@catalogue_path),
         {:ok, json} <- Jason.decode(body) do
      {:noreply, items_table, {:continue, {:insert_items, json}}}
    else
      _ ->
        Logger.error("Error when trying to load the items catalogue.")
        {:stop, {:shutdown, :load_error}, items_table}
    end
  end

  def handle_continue({:insert_items, loaded_items}, items_table) do
    Enum.each(loaded_items, &insert_item(&1, items_table))
    {:noreply, items_table}
  end

  @impl true
  def handle_call({:get_item, item_identifier}, _from, items_table) do
    item =
      :ets.lookup(items_table, item_identifier)
      |> List.first()

    {:reply, item, items_table}
  end

  def handle_call(:get_all, _from, items_table),
    do: {:reply, :ets.tab2list(items_table), items_table}

  defp insert_item({item_identifier, item_attrs}, items_table) do
    :ets.insert(items_table, {item_identifier, item_attrs})
  end
end
