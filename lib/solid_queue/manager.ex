defmodule SolidQueue.Manager do
  alias SolidQueue.Manager
  use Slogger

  defstruct [
    queue:    nil,
    workers:  [],
  ]

  def filter_dead_workers(%Manager{workers: workers} = mgr) do
    %{ mgr | workers: do_filter_dead_workers(workers) }
  end
  defp do_filter_dead_workers(workers) when is_list(workers) do
    workers
    |> Enum.filter(&do_filter_dead_workers/1)
  end
  defp do_filter_dead_workers(worker) when is_pid(worker) do
    Process.alive?(worker)
  end

  def put_worker(%Manager{workers: prev_workers} = mgr, worker) when is_pid(worker) do
    workers =
      [ worker | prev_workers ]
      |> Enum.dedup
      |> do_filter_dead_workers
    %{ mgr | workers: workers }
  end

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @queue Keyword.get(opts, :queue)
      if is_nil(@queue) do
        raise %ArgumentError{message: "`use SolidQueue.Manager` requires a :queue keyword"}
      end

      def queue, do: @queue

      def start_link() do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end

      def init(_) do
        {:ok, %SolidQueue.Manager{queue: @queue}}
      end
      
      def workers() do
        GenServer.call(__MODULE__, :get_workers)
      end

      def run_workers() do
        GenServer.cast(__MODULE__, :run_workers)
      end

      def add_worker(worker) when is_pid(worker) do
        GenServer.call(__MODULE__, {:add_worker, worker})
      end

      def handle_call({:add_worker, worker}, _from, state) do
        run_worker(worker)
        reply = {:reply, :ok, SolidQueue.Manager.put_worker(state, worker) }
        Slogger.debug("SolidQueue - #{__MODULE__ |> Module.split |> Enum.join(".")}(#{inspect self()}) added worker #{inspect worker}")
        reply
      end
      def handle_call(:get_workers, _from, state) do
        {:reply, state.workers, state}
      end

      def handle_cast(:run_workers, %{workers: workers} = state) do
        %{workers: workers} = state = SolidQueue.Manager.filter_dead_workers(state)
        Enum.each(workers, &run_worker/1)
        {:noreply, state}
      end

      def handle_info({:next_please, worker}, state) do
        run_worker(worker)
        {:noreply, state}
      end

      def should_be_running?() do
        @queue.running?()
      end

      defp run_worker(worker) do
        if should_be_running?() do
          send(worker, {:run_worker, self()})
        end
      end

    end
  end


end