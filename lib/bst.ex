defmodule BST do
  @moduledoc """
  A binary search tree abstract data structure.
  """

  alias BST.Node

  defstruct [:comparator, :root]

  @typedoc "The data structure stored on the data key for each node in the tree"
  @type element :: term()

  @typedoc """
  Function used to determine whether to place new nodes as a left or right subtree.

  Returns
  - 0 if a == b
  - negative integer if a < b
  - positive integer if a > b
  """
  @type comparator :: (a :: element(), b :: element() -> integer())

  @type tree :: %__MODULE__{root: Node.t() | nil, comparator: comparator()}

  @doc """
  Creates a new `tree`.

  ## Examples

      iex> tree = BST.new([0])
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: nil}
      iex> tree = BST.new([0, 1])
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: %BST.Node{data: 1, left: nil, right: nil}}
      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id - b.id end)
      iex> tree.root
      %BST.Node{
        data: %{id: 1, name: "Alice"},
        left: nil,
        right: %BST.Node{data: %{id: 2, name: "Bob"}, left: nil, right: nil}
      }

  """
  @spec new([element()], comparator()) :: tree()
  def new(elements \\ [], comparator \\ fn a, b -> a - b end)
      when is_list(elements) and is_function(comparator) do
    tree = %__MODULE__{comparator: comparator}

    Enum.reduce(elements, tree, fn element, tree ->
      insert(tree, element)
    end)
  end

  @doc """
  Adds a node to a `tree`.

  Resolves conflicts using `fun` where `a` is the existing `element` and `b` is
  the new `element`. Defaults to replacing with the new `element`.

  ## Examples

      iex> tree = BST.new([1])
      iex> tree = BST.insert(tree, 2)
      iex> tree.root
      %BST.Node{data: 1, left: nil, right: %BST.Node{data: 2, left: nil, right: nil}}

  """
  @spec insert(tree(), element(), (element(), element() -> element())) :: tree()
  def insert(%__MODULE__{} = tree, element, fun \\ fn _a, b -> b end) do
    %__MODULE__{tree | root: insert_node(tree.root, element, tree.comparator, fun)}
  end

  defp insert_node(nil, element, _comparator, _fun), do: %Node{data: element}

  defp insert_node(%Node{data: elem1, left: left, right: right} = node, elem2, comparator, fun) do
    case compare(elem2, elem1, comparator) do
      :eq -> %Node{node | data: fun.(elem1, elem2)}
      :lt -> %Node{node | left: insert_node(left, elem2, comparator, fun)}
      :gt -> %Node{node | right: insert_node(right, elem2, comparator, fun)}
    end
  end

  @doc """
  Removes a node from `tree` if one is found with data matching `element`.

  ## Examples

      iex> tree = BST.new([0, 1])
      iex> tree = BST.remove(tree, 1)
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: nil}
      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id - b.id end)
      iex> tree = BST.remove(tree, %{id: 1})
      iex> tree.root
      %BST.Node{data: %{id: 2, name: "Bob"}, left: nil, right: nil}

  """
  @spec remove(tree(), element()) :: tree()
  def remove(%__MODULE__{} = tree, element) do
    %__MODULE__{tree | root: remove_node(tree.root, element, tree.comparator)}
  end

  defp remove_node(nil, _element, _comparator), do: nil

  defp remove_node(%Node{data: elem1, left: left, right: right} = node, elem2, comparator) do
    case compare(elem2, elem1, comparator) do
      :eq -> promote(left, right, comparator)
      :lt -> %Node{node | left: remove_node(left, elem2, comparator)}
      :gt -> %Node{node | right: remove_node(right, elem2, comparator)}
    end
  end

  defp promote(nil, nil, _comparator), do: nil
  defp promote(%Node{} = left, nil, _comparator), do: left
  defp promote(nil, %Node{} = right, _comparator), do: right

  defp promote(%Node{} = left, %Node{} = right, comparator) do
    %Node{data: element} = leftmost_child(right)
    right = remove_node(right, element, comparator)
    %Node{data: element, left: left, right: right}
  end

  defp leftmost_child(%Node{left: nil} = node), do: node
  defp leftmost_child(%Node{left: %Node{} = node}), do: leftmost_child(node)

  @doc """
  Updates a node using `fun`, but only if a node is found with the data in `element`.

  `fun` will be invoked with the existing node's data as the first argument, and `element` as
  the second argument. This allows the node to be looked up and updated all in one pass.
  If `fun` returns `nil`, the node will be removed.

  ## Examples

      iex> tree =
      ...>   BST.new([], fn a, b -> a.id - b.id end)
      ...>   |> BST.insert(%{id: 1, name: "Alice", hobbies: ["Painting"]})
      ...>   |> BST.insert(%{id: 2, name: "Bob", hobbies: ["Programming"]})
      ...>   |> BST.update(%{id: 2, hobbies: ["Biking"]}, fn a, b ->
      ...>     %{a | hobbies: [hd(b.hobbies) | a.hobbies]}
      ...>   end)
      iex> tree.root
      %BST.Node{
        data: %{hobbies: ["Painting"], id: 1, name: "Alice"},
        left: nil,
        right: %BST.Node{
          data: %{hobbies: ["Biking", "Programming"], id: 2, name: "Bob"},
          left: nil,
          right: nil
        }
      }
      iex> tree =
      ...>   BST.update(tree, %{id: 1}, fn a, _b ->
      ...>     case Enum.reject(a.hobbies, &(&1 == "Painting")) do
      ...>       [] -> nil
      ...>       hobbies -> %{a | hobbies: hobbies}
      ...>     end
      ...>   end)
      iex> tree.root
      %BST.Node{
        data: %{hobbies: ["Biking", "Programming"], id: 2, name: "Bob"},
        left: nil,
        right: nil
      }

  """
  @spec update(tree(), element(), (element(), element() -> element() | nil)) :: tree()
  def update(%__MODULE__{} = tree, element, fun) when is_function(fun, 2) do
    %__MODULE__{tree | root: update_node(tree.root, element, tree.comparator, fun)}
  end

  defp update_node(nil, _element, _comparator, _fun), do: nil

  defp update_node(%Node{data: elem1, left: left, right: right} = node, elem2, comparator, fun) do
    case compare(elem2, elem1, comparator) do
      :eq -> update_or_promote(node, elem2, comparator, fun)
      :lt -> %Node{node | left: update_node(left, elem2, comparator, fun)}
      :gt -> %Node{node | right: update_node(right, elem2, comparator, fun)}
    end
  end

  defp update_or_promote(%Node{data: elem1} = node, elem2, comparator, fun) do
    case fun.(elem1, elem2) do
      nil -> promote(node.left, node.right, comparator)
      element -> %Node{node | data: element}
    end
  end

  @doc """
  Removes all nodes from a `tree`.

  ## Examples

      iex> tree = BST.new([0])
      iex> tree = BST.clear(tree)
      iex> tree.root
      nil

  """
  @spec clear(tree()) :: tree()
  def clear(%__MODULE__{} = tree), do: %__MODULE__{tree | root: nil}

  @doc """
  Returns a node's data matching `element`, or `nil` if not found.

  ## Examples

      iex> tree = BST.new([0, 1])
      iex> BST.find(tree, 1)
      1

      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id - b.id end)
      iex> BST.find(tree, %{id: 1})
      %{id: 1, name: "Alice"}

  """
  @spec find(tree(), element()) :: element() | nil
  def find(%__MODULE__{} = tree, element) do
    find_node(tree.root, element, tree.comparator)
  end

  defp find_node(nil, _element, _comparator), do: nil

  defp find_node(%Node{data: elem1, left: left, right: right}, elem2, comparator) do
    case compare(elem2, elem1, comparator) do
      :eq -> elem1
      :lt -> find_node(left, elem2, comparator)
      :gt -> find_node(right, elem2, comparator)
    end
  end

  @doc """
  Returns a list of a `tree`'s `element`s in order.

  Invokes `fun` on each `element` to transform it before adding it to the list.

  ## Examples

      iex> BST.new([0])
      ...> |> BST.insert(1)
      ...> |> BST.insert(-1)
      ...> |> BST.to_list()
      [-1, 0, 1]

      iex> tree =
      ...>   BST.new([], fn a, b -> a.id - b.id end)
      ...>   |> BST.insert(%{id: 1, name: "Alice"})
      ...>   |> BST.insert(%{id: 3, name: "Charlie"})
      ...>   |> BST.insert(%{id: 2, name: "Bob"})
      iex> BST.to_list(tree, fn a -> a.name end)
      ["Alice", "Bob", "Charlie"]

  """
  @spec to_list(tree(), (element() -> any())) :: [element()]
  def to_list(%__MODULE__{} = tree, fun \\ fn a -> a end) do
    tree.root
    |> list_nodes([], fun)
    |> Enum.reverse()
  end

  defp list_nodes(nil, acc, _fun), do: acc

  defp list_nodes(%Node{data: data, left: left, right: right}, acc, fun) do
    lower_values = list_nodes(left, acc, fun)
    list_nodes(right, [fun.(data) | lower_values], fun)
  end

  @doc """
  Returns the minimum `element` in a `tree`, or `nil` if empty.

  ## Examples

      iex> tree = BST.new([2, 1, 3])
      iex> BST.min(tree)
      1

  """
  @spec min(tree()) :: element() | nil
  def min(%__MODULE__{root: nil} = _tree), do: nil
  def min(%__MODULE__{root: node}), do: find_min(node)

  defp find_min(%Node{data: data, left: nil}), do: data
  defp find_min(%Node{left: %Node{} = node}), do: find_min(node)

  @doc """
  Returns the maximum `element` in a `tree`, or `nil` if empty.

  ## Examples

      iex> tree = BST.new([2, 3, 1])
      iex> BST.max(tree)
      3

  """
  @spec max(tree()) :: element() | nil
  def max(%__MODULE__{root: nil} = _tree), do: nil
  def max(%__MODULE__{root: node}), do: find_max(node)

  defp find_max(%Node{data: data, right: nil}), do: data
  defp find_max(%Node{right: %Node{} = node}), do: find_max(node)

  @doc """
  Returns the height of a `tree`.

  ## Examples

      iex> tree = BST.new([0, -3, 5, 10])
      iex> BST.height(tree)
      2

  """
  @spec height(tree()) :: integer()
  def height(%__MODULE__{root: nil} = _tree), do: -1

  def height(%__MODULE__{root: root}) do
    root
    |> node_height(0)
    |> Enum.max()
  end

  defp node_height(nil, _height), do: []

  defp node_height(%Node{left: left, right: right}, height) do
    [height] ++ node_height(left, height + 1) ++ node_height(right, height + 1)
  end

  defp compare(a, b, comparator) do
    val = comparator.(a, b)

    cond do
      val == 0 -> :eq
      val < 0 -> :lt
      val > 0 -> :gt
    end
  end
end
