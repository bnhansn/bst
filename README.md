This library provides an implementation of the Binary Search Tree abstract data structure.

## Quickstart

Tree with integer keys

```elixir
iex> tree = BST.new()
%BST{comparator: #Function<2.120876682/2 in BST.new/0>, root: nil}
iex> tree =
...>   tree |>
...>   BST.insert(0) |>
...>   BST.insert(2) |>
...>   BST.insert(1) |>
...>   BST.insert(3)
%BST{
  comparator: #Function<2.120876682/2 in BST.new/0>,
  root: %BST.Node{
    data: 0,
    left: nil,
    right: %BST.Node{
      data: 2,
      left: %BST.Node{data: 1, left: nil, right: nil},
      right: %BST.Node{data: 3, left: nil, right: nil}
    }
  }
}
iex> BST.find(tree, 2)
2
iex> BST.remove(tree, 2)
%BST{
  comparator: #Function<2.120876682/2 in BST.new/0>,
  root: %BST.Node{
    data: 0,
    left: nil,
    right: %BST.Node{
      data: 3,
      left: %BST.Node{data: 1, left: nil, right: nil},
      right: nil
    }
  }
}
```

Tree with complex data structures

```elixir
iex> tree = BST.new([], fn a, b -> a.price - b.price end)
%BST{comparator: #Function<12.128620087/2 in :erl_eval.expr/5>, root: nil}
iex> orders = [
...>   %{id: "46dffef1-cfee-4752-8922-b458e055245f", amount: 1, price: 100},
...>   %{id: "90d96a3e-e6d2-4153-af51-619b552ee049", amount: 2, price: 105},
...>   %{id: "8ffa1e69-ec51-4cce-bdcb-22b55514b5e9", amount: 6, price: 105},
...>   %{id: "b5a8b8b5-b600-42f4-a2c9-26b183effb0f", amount: 3, price: 99},
...>   %{id: "613e89eb-8a41-44c2-9b35-3178d3d7381d", amount: 3, price: 99}
...> ]
iex> tree = Enum.reduce(orders, tree, fn %{price: price} = order, tree ->
...>          BST.insert(tree, %{price: price, orders: [order]}, fn a, b ->
...>            %{orders: existing_orders} = a
...>            %{orders: [new_order]} = b
...>            %{a | orders: [new_order | existing_orders]}
...>          end)
...>        end)
%BST{
  comparator: #Function<12.128620087/2 in :erl_eval.expr/5>,
  root: %BST.Node{
    data: %{
      orders: [
        %{amount: 1, id: "46dffef1-cfee-4752-8922-b458e055245f", price: 100}
      ],
      price: 100
    },
    left: %BST.Node{
      data: %{
        orders: [
          %{amount: 3, id: "613e89eb-8a41-44c2-9b35-3178d3d7381d", price: 99},
          %{amount: 3, id: "b5a8b8b5-b600-42f4-a2c9-26b183effb0f", price: 99}
        ],
        price: 99
      },
      left: nil,
      right: nil
    },
    right: %BST.Node{
      data: %{
        orders: [
          %{amount: 6, id: "8ffa1e69-ec51-4cce-bdcb-22b55514b5e9", price: 105},
          %{amount: 2, id: "90d96a3e-e6d2-4153-af51-619b552ee049", price: 105}
        ],
        price: 105
      },
      left: nil,
      right: nil
    }
  }
}
iex> BST.update(tree, %{price: 99}, fn a, _b ->
...>   case Enum.reject(a.orders, &(&1.id == "b5a8b8b5-b600-42f4-a2c9-26b183effb0f")) do
...>     [] -> nil
...>     orders -> %{a | orders: orders}
...>   end
...> end)
%BST{
  comparator: #Function<12.128620087/2 in :erl_eval.expr/5>,
  root: %BST.Node{
    data: %{
      orders: [
        %{amount: 1, id: "46dffef1-cfee-4752-8922-b458e055245f", price: 100}
      ],
      price: 100
    },
    left: %BST.Node{
      data: %{
        orders: [
          %{amount: 3, id: "613e89eb-8a41-44c2-9b35-3178d3d7381d", price: 99}
        ],
        price: 99
      },
      left: nil,
      right: nil
    },
    right: %BST.Node{
      data: %{
        orders: [
          %{amount: 6, id: "8ffa1e69-ec51-4cce-bdcb-22b55514b5e9", price: 105},
          %{amount: 2, id: "90d96a3e-e6d2-4153-af51-619b552ee049", price: 105}
        ],
        price: 105
      },
      left: nil,
      right: nil
    }
  }
}
```

## Contributing

PRs welcome

## License

MIT
