defmodule BST.Node do
  defstruct [:data, :left, :right]

  @type t :: %__MODULE__{
          data: BST.element(),
          left: t() | nil,
          right: t() | nil
        }
end
