defmodule SolidQueue do

  defmacro __using__(_) do
    quote do
      require SolidQueue.Transaction
      import SolidQueue.Transaction
      alias SolidQueue.{
        Entry,
        Schema,
        Status,
        Timestamp,
      }

      use Slogger
      @log_prefix "SolidQueue - #{__MODULE__ |> to_string |> String.replace_prefix("Elixir.", "")} "

      defmodule Module.concat(__MODULE__, "Waiting") do
        use SolidQueue.Queue
      end

      defmodule Module.concat(__MODULE__, "InProgress") do
        use SolidQueue.Queue
      end

      defmodule Module.concat(__MODULE__, "Errored") do
        use SolidQueue.Queue
      end

      this_module = __MODULE__
      defmodule Module.concat(__MODULE__, "Manager") do
        use SolidQueue.Manager, queue: this_module
      end

      alias __MODULE__.{
        Waiting,
        InProgress,
        Errored,
        Manager,
      }


      def start_link do
        start_link([node()])
      end

      def start_link(nodes) when is_list(nodes) do
        case do_start(nodes) do
          :ok -> 
            started = Manager.start_link()
            Slogger.debug(@log_prefix <> "started on #{inspect nodes}")
            started
          err ->
            err
        end
      end

      @schema_tables [
        Waiting,
        InProgress,
        Errored,
        SolidQueue.Status,
        SolidQueue.Counter,
      ]

      defp do_start(nodes) when is_list(nodes) do
        with _ <- :ok,
          :ok <- Schema.create_schema(nodes),
          :ok <- Schema.start_mnesia(),
          :ok <- Schema.migrate_queue(nodes, Waiting),
          :ok <- Schema.migrate_queue(nodes, InProgress),
          :ok <- Schema.migrate_queue(nodes, Errored),
          :ok <- Schema.migrate_counter(nodes),
          :ok <- Schema.migrate_status(nodes),
          :ok <- Schema.wait_for_tables(@schema_tables),
          _   <- SolidQueue.Status.add_queue(__MODULE__)
        do
          :ok
        else
          err -> err
        end
      end

      defp next_id do
        SolidQueue.Counter.next_id(__MODULE__)
      end

      def enqueue(payload, ttl_sec \\ :never) # 1 hour
      def enqueue(payload, :never) do
        id = next_id()
        ts = Timestamp.now()
        do_enqueue(id, payload, :never, ts)
      end
      def enqueue(payload, ttl_sec) when is_integer(ttl_sec) do
        id = next_id()
        ts = Timestamp.now()
        do_enqueue(id, payload, ts + ttl_sec, ts)
      end

      defp do_enqueue(id, payload, expires, timestamp) do
        entry = transact do
          Waiting.enqueue(%Entry{
            id:         id,
            payload:    payload,
            timestamp:  timestamp,
            expires:    expires,
          })
        end
        start_running()
        entry
      end

      def pop do
        transact do
          with :ok <- :ok,
            :ok <- allowed_to_pop(),
            {:ok, entry} <- Waiting.pop(),
            entry <- InProgress.enqueue(entry)
          do
            {:ok, entry}
          else
            {:error, _} = err ->
              err
          end
        end
      end

      def allowed_to_pop() do
        case suspended?() do
          true -> {:error, :queue_is_suspended}
          false -> :ok
        end
      end

      def finish(%Entry{id: id}) do
        finish(id)
      end
      def finish(id) when is_integer(id) do
        transact do
          Waiting.remove(id)
          InProgress.remove(id)
          Errored.remove(id)
        end
      end

      def errorize(entry, {:error, reason}) do
        errorize(entry, reason)
      end
      def errorize(%Entry{id: id, payload: payload} = entry, reason) do
        transact do
          Waiting.remove(id)
          InProgress.remove(id)
          Errored.enqueue(%{ entry | payload: SolidQueue.Error.new(payload, reason) })
        end
      end
      def errorize(items, reason) when is_list(items) do
        Enum.map(items, fn item -> errorize(item, reason) end)
      end

      def errors do
        Errored.list()
      end

      def waiting do
        Waiting.list()
      end

      def in_progress do
        InProgress.list()
      end

      def clear_errors do
        Errored.clear()
      end

      def add_worker(worker) when is_pid(worker) do
        Manager.add_worker(worker)
      end

      def workers do
        Manager.workers()
      end

      def suspend do
        Status.suspend_queue(__MODULE__)
      end

      def resume do
        stat = Status.resume_queue(__MODULE__)
        Manager.run_workers()
        stat
      end

      def status do
        Status.get_queue(__MODULE__)
      end

      def running? do
        case status() do
          {:ok, %{:running? => true}} -> true
          _ -> false
        end
      end

      def suspended? do
        case status() do
          {:ok, %{:suspended? => true}} -> true
          _ -> false
        end
      end

      def stop_running do
        Status.stop_running(__MODULE__)
      end
      def start_running do
        stat = Status.start_running(__MODULE__)
        Manager.run_workers()
        stat
      end

      def errorize_expired do
        transact do
          waiting_ids = Waiting.expired()
          in_prog_ids = InProgress.expired()
          waiting_errors =
            waiting_ids
            |> Enum.map(&Waiting.get_by_id/1)
            |> keep_oks
            |> errorize(:expired_while_waiting)
          in_prog_errors = 
            in_prog_ids
            |> Enum.map(&InProgress.get_by_id/1)
            |> keep_oks
            |> errorize(:expired_while_in_progress)
          Waiting.remove(waiting_ids)
          InProgress.remove(in_prog_ids)
          waiting_errors ++ in_prog_errors
        end
      end

      defp keep_oks(items) when is_list(items) do
        items
        |> Enum.filter_map(fn
          {:ok, _}  -> true
          _         -> false
        end, fn
          {_, obj} -> obj
        end)
      end

    end
  end
end
