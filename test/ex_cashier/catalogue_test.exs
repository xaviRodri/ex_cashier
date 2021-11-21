defmodule ExCashier.CatalogueTest do
  use ExUnit.Case
  alias ExCashier.Catalogue

  describe "all/0" do
    test "Returns all the entries of the catalogue" do
      catalogue = Catalogue.all()

      assert [{"SR1", _}, {"GR1", _}, {"CF1", _}] = catalogue
      assert Enum.count(catalogue) == 3
    end
  end

  describe "get/1" do
    @existing_item "GR1"
    @nonexisting_item "NOITEM"
    test "Returns an existing item from the catalogue" do
      assert {@existing_item, %{"name" => "Green tea"}} = Catalogue.get(@existing_item)
    end

    test "Returns `nil` if the item searched does not exist in the catalogue" do
      assert Catalogue.get(@nonexisting_item) == nil
    end
  end

  describe "exist/1" do
    test "Returns `true` if the item entered exists in the catalogue" do
      assert Catalogue.exist?("GR1")
    end

    test "Returns `false` if the item entered does not exists in the catalogue" do
      refute Catalogue.exist?("not_exists")
    end
  end
end
