# ExCashier

`ExCashier`is a revolutionary cashier application that your customers will love!

Read about its features and how to install it below.

## Features

`ExCashier` handles some of the more used features in cashier apps.

### Concurrent carts

We can have multiple carts working in the app at the same time. This allows us to handle and indcredibly amount of concurrent users shopping in the application.

To use this feature, `ExCashier` registers each cart with its `user identifier`. Doing it in this way will allow us to search the carts also with this identifier.

**Note: User identifiers must be strings!**

#### Example of use 

```elixir
iex(1)> ExCashier.create_user_cart("my_user")
# This returns the individual process for our user's cart
{:ok, #PID<0.299.0>} 
```

### Adding items to the cart

We can also add items from our catalogue to our user's cart.

Is as easy as give the user and the item identifier.

We could also pass a quantity (defaults to 1), so we can add more than one at the same time.

#### Example of use

```elixir
iex(1)> ExCashier.add_item("my_user", "GR1", 3)
00:00:00.000 [debug] Added 3 item(s) GR1 to user x.
:ok
```

### Remove items from the cart

As we can add items, we should also be able to remove them.

The usability is the same as adding items. The only difference is that we can pass `:all` as a quantity, and all the item instances will be removed from the cart.

#### Example of use

```elixir
iex(1)> ExCashier.remove_item("my_user", "GR1", 2)
00:00:00.000 [debug] Removed 2 item(s) GR1 from the cart.
:ok
```

### Get the user's cart

We can get anytime our user's cart in order to check what we have added and how many of each item.

#### Example of use

```elixir
iex(1)> ExCashier.get_user_cart("my_user")
%{"GR1" => %{quantity: 1}}
```

### Checkout

Finally, we can get the final price for our cart. This will apply the available discounts so the user pays the minimum amount possible.

The available applicable discounts are:

- 2x1
- Exact drop price
- % drop price

Note: No different currencies are supported yet. Only GBP.

#### Example of use

```elixir
iex(1)> ExCashier.checkout("my_user")
{:ok, 3.11}
```

### The Catalogue

As mentioned before, we have a catalogue with different items to buy. This exists in `ExCashier.Catalogue` and is alive during the app execution.

When it starts, it will load the static catalogue and store it, so we can access it anytime.

For example, a user can get the entire catalogue or the details of one specific item from it.

```elixir
iex(1)> ExCashier.Catalogue.all()
[
  ...
  {"GR1",
   %{"discount" => %{"type" => "2x1"}, "name" => "Green tea", "price" => 3.11}},
  ...
]
```

```elixir
iex(1)> ExCashier.Catalogue.get("GR1")
{"GR1",
 %{"discount" => %{"type" => "2x1"}, "name" => "Green tea", "price" => 3.11}}
```

The catalogue can be also modified so we can add or remove new items. You can find the used static catalogue in the application config.

**Note: you must follow the items' structure defined so the app can interact with the items correctly**

Example of an item with discount:

`"GR1": {"name": "Green tea", "price": 3.11, "discount": {"type": "2x1"}}`

Example of an item without discount:

`"GR1": {"name": "Green tea", "price": 3.11}`

## Installation

In order to user `ExCashier`, you need previously only 1 requirement.

- Elixir 1.12+

Once you have Elixir installed, you must install the needed dependencies:

```shell
$ mix deps.get
```

Finally, you can run it in interactive mode using:

```shell
$ iex -S mix
```

This will start the application and load the catalogue. So from this point you can start interacting with the application like we did in the previous examples.

## Future possible features

- Ability to apply more than 1 discount to an item (if compatible)
- Interactive console with menu and displays
- Web App w/ Liveview to use the app
- ...




