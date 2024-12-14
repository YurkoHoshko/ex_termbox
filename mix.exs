defmodule ExTermbox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_termbox2,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases(),

      # Docs
      name: "ExTermbox2",
      source_url: "https://github.com/YurkoHoshko/ex_termbox2",
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:credo, "~> 1.7.10", only: [:dev, :test], runtime: false},
      {:zigler, "~> 0.13.2", runtime: false}
    ]
  end

  defp description do
    "Termbox2 bindings for Elixir"
  end

  defp package do
    [
      files: ~w(
        c_src/termbox2/*.{a,o,h,dylib,sh}
        c_src/termbox2/Makefile
        priv/.keep
        lib
        Makefile
        mix.exs
        README.md
        LICENSE
      ),
      maintainers: ["Yurko Hoshko"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/YurkoHoshko/ex_termbox2"}
    ]
  end

  defp aliases do
    [
      test: "test --exclude integration",
      "test.integration": "test --only integration"
    ]
  end
end
