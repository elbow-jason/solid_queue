defmodule SolidQueue.Worker do

  @callback handle_job(any) :: :ok | {:error, String.t | atom}

  defmacro __using__(opts) do
    quote do
      alias SolidQueue.Entry
      use GenServer
      use Slogger

      opts = unquote(opts)
      @queue Keyword.get(opts, :queue)
      if is_nil(@queue) do
        raise %ArgumentError{message: "`use SolidQueue.Worker` requires a :queue keyword"}
      end

      @pretty_module __MODULE__ |> Module.split() |> Enum.join(".")

      def queue, do: @queue

      def handle_info(:register_worker, state) do
        @queue.add_worker(self())
        {:noreply, state}
      end

      def handle_info({:run_worker, manager}, state) do
        handle_pop(@queue.pop, state)
        send(manager, {:next_please, self()})
        {:noreply, state}
      end

      defp handle_pop({:ok, %Entry{payload: payload} = entry}, state) do
        #call handle_job and (:ok) finish job or {:error, _} errorize job
        Slogger.debug(@pretty_module <> "(#{inspect self()}) begins handling job #{entry.id} #{inspect entry}")
        case handle_job(payload, state) do
          :ok ->
            Slogger.debug(@pretty_module <> "(#{inspect self()}) succeeded handling job #{entry.id}")
            @queue.finish(entry)
          err ->
            handle_error({:returned, err})
        end
      end
      defp handle_pop({:error, :queue_is_suspended}, state) do
        # change the queue status to running? = false
        @queue.stop_running()
        {:ok, state}
      end
      defp handle_pop({:error, :empty_queue}, state) do
        # change the queue status to running? = false
        @queue.stop_running()
        {:ok, state}
      end
      @before_compile SolidQueue.Worker
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      
      def handle_error({:returned, {:error, _} = err}) do
        Slogger.error(@pretty_module <> "(#{inspect self()}) general error occured while handling job #{entry.id} #{inspect err}")
        @queue.errorize(entry, err)
      end
      def handle_error({:returned, err}) do
        Slogger.error(@pretty_module <> "(#{inspect self()}) bad return handling job #{entry.id} #{inspect err}")
        @queue.errorize(entry, {:error, {:invalid_return, err}})
      end

      def handle_error(anything) do
        Slogger.warn("#{@pretty_module}.handle_error/1 got an unmatched/unhandled error. #{inspect anything}")
      end

      if !Module.defines?(__MODULE__, {:start_link, 1}) do
        def start_link(opts \\ nil) do
          case GenServer.start_link(__MODULE__, nil, []) do
            {:ok, pid} ->
              send(pid, :register_worker)
              {:ok, pid}
            err ->
              err
          end
        end
      end

    end
  end

end