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

defmodule ExampleQueue.Cleaner do
  use SolidQueue.Cleaner,
    queue: ExampleQueue,
    interval: 1000, #ms
end

defmodule ExampleQueue.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(ExampleQueue, []),
      worker(ExampleWorker, [id: :example_worker_01], id: :example_worker_01),
      worker(ExampleWorker, [id: :example_worker_02], id: :example_worker_02),
      worker(ExampleWorker, [id: :example_worker_03], id: :example_worker_03),
      worker(ExampleWorker, [id: :example_worker_04], id: :example_worker_04),
      worker(ExampleQueue.Cleaner, []),

      # Starts a worker by calling: SolidQueue.Worker.start_link(arg1, arg2, arg3)
      # worker(SolidQueue.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExampleQueue.Supervisor]
    Supervisor.start_link(children, opts)
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

