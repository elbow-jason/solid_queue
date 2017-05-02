# SolidQueue

**TODO: Add description**

## Usage

```elixir

    defmodule ExampleQueue do
      use SolidQueue
    end

    defmodule ExampleWorker do
      use SolidQueue.Worker, queue: ExampleQueue

      def handle_job("please_error" <> _ = job, _state) do
        IO.puts("#{__MODULE__} will now error a job #{inspect job}")
        {:error, :please_error}
      end
      def handle_job({:sleep, sec}, _state) do
        IO.puts("#{__MODULE__} #{inspect self()} Going to sleep for #{inspect sec} seconds...")
        :timer.sleep(sec * 1000)
        IO.puts("#{__MODULE__} #{inspect self()} Done Sleeping.")
        :ok
      end
      def handle_job(func, _state) when is_function(func, 0) do
        func.()
      end
      def handle_job(job, _state) do
        # returns ok... should finish and disappear
        IO.puts("#{__MODULE__} #{inspect self()} got a job #{inspect job}")
        :ok
      end
    end

```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `solid_queue` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:solid_queue, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/solid_queue](https://hexdocs.pm/solid_queue).

