defmodule BST.MixProject do
  use Mix.Project

  def project do
    [
      app: :bst,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: "Binary Search Tree",
      source_url: "https://github.com/bnhansn/bst"
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "BST",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: :bst,
      maintainers: ["Ben Hansen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bnhansn/bst"}
    ]
  end
end
