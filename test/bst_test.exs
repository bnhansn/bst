defmodule BSTTest do
  use ExUnit.Case
  doctest BST

  alias BST.Node

  describe "new/2" do
    test "creates an empty tree when given an empty list and comparator" do
      assert %BST{root: nil} = BST.new([], fn a, b -> a <= b end)
    end

    test "creates a tree with a root node when given one element" do
      assert %BST{root: %Node{data: 0, left: nil, right: nil}} = BST.new(0)
    end

    test "creates a tree with branches when given multiple elements" do
      assert %BST{
               root: %Node{data: 0, left: nil, right: %Node{data: 1, left: nil, right: nil}}
             } = BST.new([0, 1])
    end
  end

  describe "insert/2" do
    test "inserts a lower value on the left" do
      tree = BST.insert(BST.new(0), -1)

      assert tree.root.data == 0
      assert tree.root.left.data == -1
    end

    test "inserts a higher value on the right" do
      tree = BST.insert(BST.new(0), 1)

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

      assert tree.root.data == 0
      assert tree.root.left.data == -2
      assert tree.root.left.left.data == -3
      assert tree.root.left.right.data == -1
      assert tree.root.right.data == 2
      assert tree.root.right.left.data == 1
      assert tree.root.right.right.data == 3
    end

    test "does not insert duplicate keys" do
      assert %BST{root: %{data: 0, left: nil, right: nil}} = BST.insert(BST.new(0), 0)

      list = [0, -2, 2, -3, -1, 3, 1]
      tree = BST.new(list)

      assert tree
             |> BST.to_list()
             |> length() == length(list)

      tree =
        Enum.reduce(list, tree, fn i, tree ->
          BST.insert(tree, i)
        end)

      assert tree
             |> BST.to_list()
             |> length() == length(list)
    end

    test "inserts branches using a given comparator" do
      tree =
        BST.new([], fn a, b -> a.id - b.id end)
        |> BST.insert(%{id: 3, name: "Charlie"})
        |> BST.insert(%{id: 2, name: "Bob"})
        |> BST.insert(%{id: 1, name: "Alice"})
        |> BST.insert(%{id: 4, name: "Dan"})

      assert tree.root.data == %{id: 3, name: "Charlie"}
      assert tree.root.left.data == %{id: 2, name: "Bob"}
      assert tree.root.left.left.data == %{id: 1, name: "Alice"}
      assert tree.root.right.data == %{id: 4, name: "Dan"}
    end

    test "overwrites keys by default on conflict" do
      tree =
        BST.new([], fn a, b -> a.id - b.id end)
        |> BST.insert(%{id: 1, name: "Alice"})
        |> BST.insert(%{id: 2, name: "Bob"})
        |> BST.insert(%{id: 3, name: "Charlie"})

      assert %{id: 3, name: "Charlie"} = tree.root.right.right.data

      tree = BST.insert(tree, %{id: 3, name: "Chuck"})

      assert %{id: 3, name: "Chuck"} = tree.root.right.right.data
    end

    test "resolves conflicts using a given function" do
      tree =
        BST.new([], fn a, b -> a.length - b.length end)
        |> BST.insert(%{length: 3, names: ["Bob", "Dan", "Eve"]})
        |> BST.insert(%{length: 5, names: ["Alice", "Carol", "Frank"]})

      assert tree.root.right.data.names == ["Alice", "Carol", "Frank"]

      tree =
        BST.insert(tree, %{length: 5, names: ["Grace"]}, fn a, b ->
          %{a | names: a.names ++ b.names}
        end)

      assert tree.root.right.data.names == ["Alice", "Carol", "Frank", "Grace"]
    end
  end

  describe "remove/3" do
    test "removes root when it is the only node" do
      tree = BST.new(0)

      assert tree.root.data == 0

      tree = BST.remove(tree, 0)

      assert tree.root == nil
    end

    test "removes lower node" do
      tree = BST.new([0, -1])

      assert tree.root.left.data == -1

      tree = BST.remove(tree, -1)

      assert tree.root.left == nil
    end

    test "removes higher node" do
      tree = BST.new([0, 1])

      assert tree.root.right.data == 1

      tree = BST.remove(tree, 1)

      assert tree.root.right == nil
    end

    test "removes nested nodes" do
      tree = BST.new([0, -2, -1, 2, 1])

      assert tree.root.left.right.data == -1
      assert tree.root.right.left.data == 1

      assert tree
             |> BST.to_list()
             |> length() == 5

      tree =
        tree
        |> BST.remove(-1)
        |> BST.remove(1)

      assert tree.root.left.right == nil
      assert tree.root.right.left == nil

      assert tree
             |> BST.to_list()
             |> length() == 3
    end

    test "promotes the left subtree of a removed node if its right subtree is nil" do
      tree = BST.new([0, 2, 1])

      assert tree.root.right.data == 2
      assert tree.root.right.right == nil
      assert tree.root.right.left.data == 1
      assert tree |> BST.to_list() |> length() == 3

      tree = BST.remove(tree, 2)

      assert tree.root.right.data == 1
      assert tree |> BST.to_list() |> length() == 2
    end

    test "promotes the right subtree of a removed node if its left subtree is nil" do
      tree = BST.new([0, 1, 2])

      assert tree.root.right.data == 1
      assert tree.root.right.left == nil
      assert tree.root.right.right.data == 2
      assert tree |> BST.to_list() |> length() == 3

      tree = BST.remove(tree, 1)

      assert tree.root.right.data == 2
      assert tree |> BST.to_list() |> length() == 2
    end

    test "removes a node with a given comparator" do
      tree =
        BST.new([], fn a, b -> a.id - b.id end)
        |> BST.insert(%{id: 1, name: "Alice"})
        |> BST.insert(%{id: 2, name: "Bob"})
        |> BST.insert(%{id: 3, name: "Charlie"})

      assert tree |> BST.to_list() |> length() == 3
      assert tree.root.right.right.data == %{id: 3, name: "Charlie"}

      tree = BST.remove(tree, %{id: 3})

      assert tree.root.right.right == nil
      assert tree |> BST.to_list() |> length() == 2
    end

    test "promotes leftmost child of right subtree when a removed node has a left and right subtree" do
      tree = BST.new([0, 5, 3, 7, 2, 4, 6, 8])

      assert tree.root.right.data == 5
      assert tree.root.right.right.data == 7
      assert tree.root.right.right.left.data == 6
      assert tree |> BST.to_list() |> length() == 8

      tree = BST.remove(tree, 5)

      assert tree.root.right.data == 6
      assert tree |> BST.to_list() |> length() == 7
    end

    test "returns same tree if node is not found" do
      %BST{root: %{data: 0, right: %{data: 1}}} = tree = BST.new([0, 1])

      assert %BST{root: %{data: 0, right: %{data: 1}}} = BST.remove(tree, 3)
    end
  end

  describe "find/3" do
    test "returns an element in a tree" do
      tree = BST.new(0)

      assert 0 == BST.find(tree, 0)
    end

    test "returns an element in a tree with a given comparator" do
      tree =
        BST.new([], fn a, b -> a.id - b.id end)
        |> BST.insert(%{id: 1, name: "Alice"})
        |> BST.insert(%{id: 2, name: "Bob"})
        |> BST.insert(%{id: 3, name: "Charlie"})
        |> BST.insert(%{id: 4, name: "Charlie"})

      assert %{id: 4, name: "Charlie"} == BST.find(tree, %{id: 4})
    end

    test "returns nil if the tree is empty" do
      tree = BST.new()

      assert nil == BST.find(tree, 1)
    end

    test "returns nil if an element is not found" do
      tree = BST.new(0)

      assert nil == BST.find(tree, 1)
    end

    test "returns a lower element" do
      tree = BST.new([0, -1])

      assert tree.root.left.data == -1
      assert -1 == BST.find(tree, -1)
    end

    test "returns a higher element" do
      tree = BST.new([0, 1])

      assert tree.root.right.data == 1
      assert 1 == BST.find(tree, 1)
    end

    test "returns nested elements" do
      tree = BST.new([0, 2, 1, -2, -1])

      assert tree.root.right.left.data == 1
      assert tree.root.left.right.data == -1
      assert 1 == BST.find(tree, 1)
      assert -1 == BST.find(tree, -1)
    end
  end

  describe "to_list/2" do
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
  end

  describe "clear/1" do
    test "clears all nodes from a tree" do
      tree = BST.new([0, 1, 2])

      assert %BST{root: nil} = BST.clear(tree)
    end
  end

  describe "min/1" do
    test "returns the minimum element in the tree" do
      tree = BST.new([5, 3, 4, 1, 6, 2])

      assert 1 == BST.min(tree)
    end

    test "returns nil if tree is empty" do
      tree = BST.new()

      assert nil == BST.min(tree)
    end
  end

  describe "max/1" do
    test "returns the maximum element in the tree" do
      tree = BST.new([5, 3, 4, 1, 6, 2])

      assert 6 == BST.max(tree)
    end

    test "returns nil if tree is empty" do
      tree = BST.new()

      assert nil == BST.max(tree)
    end
  end
end
