defmodule ExCashier.UserCartTest do
  use ExUnit.Case, async: true
  alias ExCashier.UserCart
  # This will hide logs in the console when testing
  @moduletag :capture_log

  @valid_user_identifier "1234abcd"
  @invalid_user_identifier %{user: "identifier"}
  @valid_item_identifier "item1"
  @invalid_item_identifier [item: 1]

  describe "create/1" do
    setup :clean_up_carts

    test "Creates a user cart when the user identifier is valid" do
      assert {:ok, _pid} = UserCart.create(@valid_user_identifier)
    end

    test "Fails to create a user cart when the user has already a working cart" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)

      assert {:error, {:already_started, _pid}} = UserCart.create(@valid_user_identifier)
    end

    test "Fails to create a user cart if the user identifier is invalid" do
      assert :error = UserCart.create(@invalid_user_identifier)
    end
  end

  describe "add/3" do
    setup :clean_up_carts

    test "Adds an item to the user's cart if the user exists and the item is valid" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)
    end

    test "Adds an specified qty of an item to the user's cart if the user exists and the item is valid" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 3)

      assert %{@valid_item_identifier => %{quantity: 3}} = UserCart.get(@valid_user_identifier)
    end

    test "Adds more of the same items to the current cart when they previously exists in it" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)

      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 3)

      assert %{@valid_item_identifier => %{quantity: 4}} = UserCart.get(@valid_user_identifier)
    end

    test "Fails to add an item if the cart does not exist" do
      assert {:error, :not_found} = UserCart.add(@valid_user_identifier, @valid_item_identifier)
    end

    test "Fails to add an item if any of ther parameters is not valid" do
      assert :error = UserCart.add(@invalid_user_identifier, @valid_item_identifier)
      assert :error = UserCart.add(@valid_user_identifier, @invalid_item_identifier)
    end
  end

  describe "get/1" do
    setup :clean_up_carts

    test "Returns an empty cart from a new valid user" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      assert %{} = UserCart.get(@valid_user_identifier)
    end

    test "Returns a non-empty cart from a valid user" do
      {:ok, _pid} = UserCart.create(@valid_user_identifier)
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)
    end

    test "Returns an error if the user identifier is not valid" do
      assert :error = UserCart.get(@invalid_user_identifier)
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
