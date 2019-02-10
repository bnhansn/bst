defmodule BSTTest do
  use ExUnit.Case
  doctest BST

  alias BST.Node

  test "creates an empty tree when given an empty list and comparator" do
    assert %BST{root: nil, size: 0} = BST.new([], fn a, b -> a <= b end)
  end

  test "creates a tree with a root node when given one element" do
    assert %BST{root: %Node{data: 0, left: nil, right: nil}, size: 1} = BST.new(0)
  end

  test "creates a tree with branches when given multiple elements" do
    assert %BST{
             root: %Node{data: 0, left: nil, right: %Node{data: 1, left: nil, right: nil}},
             size: 2
           } = BST.new([0, 1])
  end

  test "inserts a lower value on the left" do
    tree = BST.insert(BST.new(0), -1)

    assert tree.size == 2
    assert tree.root.data == 0
    assert tree.root.left.data == -1
  end

  test "inserts the same value on the left" do
    tree = BST.insert(BST.new(0), 0)

    assert tree.size == 2
    assert tree.root.data == 0
    assert tree.root.left.data == 0
  end

  test "inserts a higher value on the right" do
    tree = BST.insert(BST.new(0), 1)

    assert tree.size == 2
    assert tree.root.data == 0
    assert tree.root.right.data == 1
  end

  test "inserts multiple branches" do
    tree =
      BST.new(0)
      |> BST.insert(-2)
      |> BST.insert(2)
      |> BST.insert(-3)
      |> BST.insert(-1)
      |> BST.insert(3)
      |> BST.insert(1)

    assert tree.size == 7
    assert tree.root.data == 0
    assert tree.root.left.data == -2
    assert tree.root.left.left.data == -3
    assert tree.root.left.right.data == -1
    assert tree.root.right.data == 2
    assert tree.root.right.left.data == 1
    assert tree.root.right.right.data == 3
  end

  test "inserts branches using a given comparator" do
    tree =
      BST.new(%{id: 1, name: "Alice"}, fn a, b -> a.id <= b.id end)
      |> BST.insert(%{id: 3, name: "Charlie"})
      |> BST.insert(%{id: 2, name: "Bob"})

    assert tree.size == 3
    assert tree.root.data == %{id: 1, name: "Alice"}
    assert tree.root.right.data == %{id: 3, name: "Charlie"}
    assert tree.root.right.left.data == %{id: 2, name: "Bob"}
  end

  test "removes root when it is the only node" do
    tree = BST.new(0)

    assert tree.size == 1
    assert tree.root.data == 0

    tree = BST.remove(tree, 0)

    assert tree.size == 0
    assert tree.root == nil
  end

  test "removes lower node" do
    tree = BST.new([0, -1])

    assert tree.size == 2
    assert tree.root.left.data == -1

    tree = BST.remove(tree, -1)

    assert tree.size == 1
    assert tree.root.left == nil
    refute BST.find(tree, -1)
  end

  test "removes higher node" do
    tree = BST.new([0, 1])

    assert tree.size == 2
    assert tree.root.right.data == 1

    tree = BST.remove(tree, 1)

    assert tree.size == 1
    assert tree.root.right == nil
    refute BST.find(tree, 1)
  end

  test "removes nested nodes" do
    tree = BST.new([0, -2, -1, 2, 1])

    assert tree.size == 5
    assert tree.root.left.right.data == -1
    assert tree.root.right.left.data == 1

    tree =
      tree
      |> BST.remove(-1)
      |> BST.remove(1)

    assert tree.size == 3
    assert tree.root.left.right == nil
    assert tree.root.right.left == nil
    refute BST.find(tree, -1)
    refute BST.find(tree, 1)
  end

  test "promotes the left subtree of a removed node if its right subtree is nil" do
    tree = BST.new([0, 2, 1])

    assert tree.size == 3
    assert tree.root.right.data == 2
    assert tree.root.right.right == nil
    assert tree.root.right.left.data == 1

    tree = BST.remove(tree, 2)

    assert tree.size == 2
    assert tree.root.right.data == 1
  end

  test "promotes the right subtree of a removed node if its left subtree is nil" do
    tree = BST.new([0, 1, 2])

    assert tree.size == 3
    assert tree.root.right.data == 1
    assert tree.root.right.left == nil
    assert tree.root.right.right.data == 2

    tree = BST.remove(tree, 1)

    assert tree.size == 2
    assert tree.root.right.data == 2
  end

  test "removes a node with a given comparator" do
    tree =
      BST.new(%{id: 1, name: "Alice"}, fn a, b -> a.id <= b.id end)
      |> BST.insert(%{id: 3, name: "Charlie"})
      |> BST.insert(%{id: 2, name: "Bob"})

    assert tree.root.right.data == %{id: 3, name: "Charlie"}

    tree = BST.remove(tree, %{id: 3}, fn a, b -> a.id == b.id end)

    assert tree.root.right.data == %{id: 2, name: "Bob"}
    refute BST.find(tree, %{id: 3}, fn a, b -> a.id == b.id end)
  end

  test "promotes leftmost child of right subtree when a removed node has a left and right subtree" do
    tree = BST.new([0, 5, 3, 7, 2, 4, 6, 8])

    assert tree.size == 8
    assert tree.root.right.data == 5
    assert tree.root.right.right.data == 7
    assert tree.root.right.right.left.data == 6

    tree = BST.remove(tree, 5)

    assert tree.size == 7
    assert tree.root.right.data == 6
  end

  test "finds an element in a tree" do
    tree = BST.new(0)

    assert 0 == BST.find(tree, 0)
  end

  test "finds an element in a tree with a given comparator" do
    tree = BST.new(%{id: 1, name: "Alice"}, fn a, b -> a.id <= b.id end)

    assert %{id: 1, name: "Alice"} == BST.find(tree, %{id: 1}, fn a, b -> a.id == b.id end)
  end

  test "find returns nil if the tree is empty" do
    tree = BST.new()

    assert nil == BST.find(tree, 1)
  end

  test "find returns nil if an element is not found" do
    tree = BST.new(0)

    assert nil == BST.find(tree, 1)
  end

  test "finds a lower element" do
    tree = BST.new([0, -1])

    assert tree.root.left.data == -1
    assert -1 == BST.find(tree, -1)
  end

  test "finds a higher element" do
    tree = BST.new([0, 1])

    assert tree.root.right.data == 1
    assert 1 == BST.find(tree, 1)
  end

  test "finds nested elements" do
    tree = BST.new([0, 2, 1, -2, -1])

    assert tree.root.right.left.data == 1
    assert tree.root.left.right.data == -1
    assert 1 == BST.find(tree, 1)
    assert -1 == BST.find(tree, -1)
  end

  test "returns one element in a list" do
    tree = BST.new(0)

    assert [0] == BST.to_list(tree)
  end

  test "returns lower elements ordered in a list" do
    tree = BST.insert(BST.new(0), -1)

    assert [-1, 0] == BST.to_list(tree)
  end

  test "returns higher elements ordered in a list" do
    tree = BST.insert(BST.new(0), 1)

    assert [0, 1] == BST.to_list(tree)
  end

  test "returns an ordered list of node values" do
    tree =
      BST.new(0)
      |> BST.insert(-2)
      |> BST.insert(2)
      |> BST.insert(-3)
      |> BST.insert(-1)
      |> BST.insert(3)
      |> BST.insert(1)

    assert [-3, -2, -1, 0, 1, 2, 3] = BST.to_list(tree)
  end

  test "returns an ordered list when using a given comparator" do
    tree =
      BST.new(%{id: 1, name: "Alice"}, fn a, b -> a.id <= b.id end)
      |> BST.insert(%{id: 3, name: "Charlie"})
      |> BST.insert(%{id: 2, name: "Bob"})

    assert [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}, %{id: 3, name: "Charlie"}] ==
             BST.to_list(tree)
  end

  test "clears all nodes from a tree" do
    tree = BST.new([0, 1, 2])

    assert %BST{root: nil} = BST.clear(tree)
  end

  test "returns the minimum element in the tree" do
    tree = BST.new([5, 3, 4, 1, 6, 2])

    assert 1 == BST.min(tree)
  end

  test "min returns nil if tree is empty" do
    tree = BST.new()

    assert nil == BST.min(tree)
  end

  test "returns the maximum element in the tree" do
    tree = BST.new([5, 3, 4, 1, 6, 2])

    assert 6 == BST.max(tree)
  end

  test "max returns nil if tree is empty" do
    tree = BST.new()

    assert nil == BST.max(tree)
  end
end
