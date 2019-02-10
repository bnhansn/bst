defmodule BST do
  @moduledoc """
  Binary search tree abstract data structure
  """

  alias BST.Node

  defstruct root: nil, comparator: nil, size: 0

  @typedoc "The data structure stored on the data key for each node in the tree"
  @type element :: term()

  @typedoc """
  Function that returns `true` if the first argument is less than or equal to the second argument

  Used to determine whether to place new nodes as a left or right subtree
  """
  @type comparator :: (element(), element() -> as_boolean(term()))

  @type tree :: %__MODULE__{
          root: Node.t() | nil,
          comparator: comparator(),
          size: integer()
        }

  @doc """
  Creates a new `tree`

  ## Examples

      iex> tree = BST.new(0)
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: nil}
      iex> tree = BST.new([0, 1])
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: %BST.Node{data: 1, left: nil, right: nil}}
      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id <= b.id end)
      iex> tree.root
      %BST.Node{
        data: %{id: 1, name: "Alice"},
        left: nil,
        right: %BST.Node{data: %{id: 2, name: "Bob"}, left: nil, right: nil}
      }

  """
  @spec new(element() | [element()], comparator()) :: tree()
  def new(elements \\ [], comparator \\ fn a, b -> a <= b end)

  def new([], comparator), do: %__MODULE__{comparator: comparator}

  def new(element, comparator) when not is_list(element) do
    new([element], comparator)
  end

  def new(elements, comparator) when is_list(elements) do
    tree = new([], comparator)

    Enum.reduce(elements, tree, fn element, tree ->
      insert(tree, element)
    end)
  end

  @doc """
  Adds a node to a `tree`

  ## Examples

      iex> tree = BST.new(1)
      iex> tree = BST.insert(tree, 2)
      iex> tree.root
      %BST.Node{data: 1, left: nil, right: %BST.Node{data: 2, left: nil, right: nil}}

  """
  @spec insert(tree(), element()) :: tree()
  def insert(%__MODULE__{root: node, comparator: comparator, size: size} = tree, element) do
    %__MODULE__{tree | root: insert_node(node, element, comparator), size: size + 1}
  end

  defp insert_node(nil, element, _comparator) do
    %Node{data: element, left: nil, right: nil}
  end

  defp insert_node(%Node{data: elem1, left: left, right: right} = node, elem2, comparator) do
    if comparator.(elem2, elem1) do
      %Node{node | left: insert_node(left, elem2, comparator)}
    else
      %Node{node | right: insert_node(right, elem2, comparator)}
    end
  end

  @doc """
  Removes the first node from a `tree` when `fun` returns `true` using `element` as the first argument

  ## Examples

      iex> tree = BST.new([0, 1])
      iex> tree = BST.remove(tree, 1)
      iex> tree.root
      %BST.Node{data: 0, left: nil, right: nil}
      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id <= b.id end)
      iex> tree = BST.remove(tree, %{id: 1}, fn a, b -> a.id == b.id end)
      iex> tree.root
      %BST.Node{data: %{id: 2, name: "Bob"}, left: nil, right: nil}

  """
  @spec remove(tree(), element()) :: tree()
  def remove(
        %__MODULE__{root: node, comparator: comparator, size: size} = tree,
        element,
        fun \\ fn a, b -> a == b end
      ) do
    %__MODULE__{tree | root: remove_node(node, element, comparator, fun), size: size - 1}
  end

  defp remove_node(%Node{data: elem1, left: left, right: right} = node, elem2, comparator, fun) do
    cond do
      fun.(elem2, elem1) ->
        promote(left, right, comparator, fun)

      comparator.(elem2, elem1) ->
        %Node{node | left: remove_node(left, elem2, comparator, fun)}

      true ->
        %Node{node | right: remove_node(right, elem2, comparator, fun)}
    end
  end

  defp remove_node(nil, _element, _comparator, _fun), do: nil

  defp promote(nil, nil, _comparator, _fun), do: nil
  defp promote(%Node{} = left, nil, _comparator, _fun), do: left
  defp promote(nil, %Node{} = right, _comparator, _fun), do: right

  defp promote(%Node{} = left, %Node{} = right, comparator, fun) do
    %Node{data: element} = leftmost_child(right)
    right = remove_node(right, element, comparator, fun)
    %Node{data: element, left: left, right: right}
  end

  defp leftmost_child(%Node{left: nil} = node), do: node
  defp leftmost_child(%Node{left: %Node{} = node}), do: leftmost_child(node)

  @doc """
  Removes all nodes from a `tree`

  ## Examples

      iex> tree = BST.new(0)
      iex> tree = BST.clear(tree)
      iex> tree.root
      nil

  """
  @spec clear(tree()) :: tree()
  def clear(%__MODULE__{} = tree) do
    %__MODULE__{tree | root: nil, size: 0}
  end

  @doc """
  Returns the first `element` which `fun` returns `true` for using `element` as the first argument

  ## Examples

      iex> tree = BST.new([0, 1])
      iex> BST.find(tree, 1)
      1
      iex> tree = BST.new([%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}], fn a, b -> a.id <= b.id end)
      iex> BST.find(tree, %{id: 1}, fn a, b -> a.id == b.id end)
      %{id: 1, name: "Alice"}

  """
  @spec find(tree(), element(), (element() -> any())) :: element() | nil
  def find(%__MODULE__{} = tree, element, fun \\ fn a, b -> a == b end) do
    find_node(tree.root, element, tree.comparator, fun)
  end

  defp find_node(nil, _element, _comparator, _fun), do: nil

  defp find_node(%Node{data: elem1, left: left, right: right}, elem2, comparator, fun) do
    cond do
      fun.(elem1, elem2) -> elem1
      comparator.(elem2, elem1) -> find_node(left, elem2, comparator, fun)
      true -> find_node(right, elem2, comparator, fun)
    end
  end

  @doc """
  Returns a `list` of a `tree`'s `element`s in order

  ## Examples

      iex> BST.new(0)
      ...> |> BST.insert(1)
      ...> |> BST.insert(-1)
      ...> |> BST.to_list()
      [-1, 0, 1]

  """
  @spec to_list(tree()) :: [element()]
  def to_list(%__MODULE__{} = tree) do
    tree.root
    |> list_nodes([])
    |> Enum.reverse()
  end

  defp list_nodes(nil, acc), do: acc

  defp list_nodes(%Node{data: data, left: left, right: right}, acc) do
    lower_values = list_nodes(left, acc)
    list_nodes(right, [data | lower_values])
  end

  @doc """
  Returns the minimum `element` in a `tree`, or `nil` if empty

  ## Examples

      iex> tree = BST.new([2, 1, 3])
      iex> BST.min(tree)
      1

  """
  @spec min(tree()) :: element() | nil
  def min(%__MODULE__{root: nil} = _tree), do: nil
  def min(%__MODULE__{root: node}), do: min(node)
  def min(%Node{data: data, left: nil}), do: data
  def min(%Node{left: %Node{} = node}), do: min(node)

  @doc """
  Returns the maximum `element` in a `tree`, or `nil` if empty

  ## Examples

      iex> tree = BST.new([2, 3, 1])
      iex> BST.max(tree)
      3

  """
  @spec max(tree()) :: element() | nil
  def max(%__MODULE__{root: nil} = _tree), do: nil
  def max(%__MODULE__{root: node}), do: max(node)
  def max(%Node{data: data, right: nil}), do: data
  def max(%Node{right: %Node{} = node}), do: max(node)
end
