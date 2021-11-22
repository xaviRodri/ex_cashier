defmodule ExCashier.UserCartTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  require Logger
  alias ExCashier.UserCart
  # This will hide logs in the console when testing
  @moduletag :capture_log

  @valid_user_identifier "1234abcd"
  @invalid_user_identifier %{user: "identifier"}
  @valid_item_identifier "GR1"
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
    setup :create_and_cleanup

    test "Adds an item to the user's cart if the user exists and the item is valid" do
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)
    end

    test "Adds an specified qty of an item to the user's cart if the user exists and the item is valid" do
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 3)

      assert %{@valid_item_identifier => %{quantity: 3}} = UserCart.get(@valid_user_identifier)
    end

    test "Adds more of the same items to the current cart when they previously exists in it" do
      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 3)

      assert %{@valid_item_identifier => %{quantity: 4}} = UserCart.get(@valid_user_identifier)
    end

    test "Fails to add an item if the cart does not exist" do
      assert {:error, :not_found} = UserCart.add("non_registered_user", @valid_item_identifier)
    end

    test "Fails to add an item if the item does not exist" do
      assert {:error, :item_not_found} = UserCart.add(@valid_user_identifier, "not_exists")
    end

    test "Fails to add an item if any of ther parameters is not valid" do
      assert :error = UserCart.add(@invalid_user_identifier, @valid_item_identifier)
      assert :error = UserCart.add(@valid_user_identifier, @invalid_item_identifier)
    end
  end

  describe "get/1" do
    setup :create_and_cleanup

    test "Returns an empty cart from a new valid user" do
      assert %{} = UserCart.get(@valid_user_identifier)
    end

    test "Returns a non-empty cart from a valid user" do
      assert :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)
    end

    test "Returns an error if the user identifier is not valid" do
      assert :error = UserCart.get(@invalid_user_identifier)
    end
  end

  describe "remove/3" do
    setup :create_and_cleanup

    test "Removes only 1 instance of the item from the cart if no quantity is specified" do
      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 2)

      assert %{@valid_item_identifier => %{quantity: 2}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.remove(@valid_user_identifier, @valid_item_identifier)

      assert %{@valid_item_identifier => %{quantity: 1}} = UserCart.get(@valid_user_identifier)
    end

    test "Reduces the quantity of the item from the cart when quantity is specified" do
      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 10)

      assert %{@valid_item_identifier => %{quantity: 10}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.remove(@valid_user_identifier, @valid_item_identifier, 5)

      assert %{@valid_item_identifier => %{quantity: 5}} = UserCart.get(@valid_user_identifier)
    end

    test "Removes the item from the cart if the quantity specified is the same that the cart contains" do
      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 2)

      assert %{@valid_item_identifier => %{quantity: 2}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.remove(@valid_user_identifier, @valid_item_identifier, 2)

      assert %{} = UserCart.get(@valid_user_identifier)
    end

    test "Removes the item from the cart if the quantity specified is `:all`" do
      :ok = UserCart.add(@valid_user_identifier, @valid_item_identifier, 10)

      assert %{@valid_item_identifier => %{quantity: 10}} = UserCart.get(@valid_user_identifier)

      :ok = UserCart.remove(@valid_user_identifier, @valid_item_identifier, :all)

      assert %{} = UserCart.get(@valid_user_identifier)
    end

    test "The cart is not affected if the item tried to remove is not in it" do
      assert :ok = UserCart.remove(@valid_user_identifier, @valid_item_identifier)
      assert %{} = UserCart.get(@valid_user_identifier)
    end

    test "Returns an `:item_not_found` error when the item tried to remove is not in the catalogue" do
      assert capture_log(fn ->
               assert {:error, :item_not_found} =
                        UserCart.remove(@valid_user_identifier, "not_exists")
             end) =~ "not found in the catalogue"
    end

    test "Returns an error if the user is not registered" do
      assert capture_log(fn ->
               assert {:error, :not_found} =
                        UserCart.remove("not_registered", @valid_item_identifier)
             end) =~ "not found"
    end

    test "Returns an error if any of the parameters is not valid" do
      assert capture_log(fn ->
               assert :error = UserCart.remove(@invalid_user_identifier, @valid_item_identifier)
             end) =~ "must be strings"

      assert capture_log(fn ->
               assert :error = UserCart.remove(@valid_user_identifier, @invalid_item_identifier)
             end) =~ "must be strings"

      assert capture_log(fn ->
               assert :error =
                        UserCart.remove(@valid_user_identifier, @valid_item_identifier, "a")
             end) =~ "positive integer or the atom `:all`"
    end
  end

  defp create_and_cleanup(_) do
    {:ok, pid} = ExCashier.create_user_cart(@valid_user_identifier)
    on_exit(fn -> DynamicSupervisor.terminate_child(ExCashier.UserCartSupervisor, pid) end)
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
