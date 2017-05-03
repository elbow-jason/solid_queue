defmodule SolidQueue.Queue do

  defmacro __using__(_opts) do
    quote do
      require SolidQueue.Transaction
      import SolidQueue.Transaction
      alias SolidQueue.Entry

      def inverse_pop do
        transact do
          __MODULE__
          |> :mnesia.last
          |> handle_pop
        end
      end

      def pop do
        transact do
          __MODULE__
          |> :mnesia.first
          |> handle_pop
        end
      end

      defp handle_pop(maybe_id) do
        with _ <- :ok,
          id when is_integer(id)  <- maybe_id,
          {:ok, entry}            <- get_by_id(id),
          :ok                     <- remove(id)
        do
          {:ok, entry}
        else
          :'$end_of_table' ->
            {:error, :empty_queue}
          err ->
            err
        end
      end

      def remove(ids) when is_list(ids) do
        Enum.map(ids, &remove/1)
      end
      def remove(%Entry{id: id}) do
        remove(id)
      end
      def remove(id) do
        transact do
          :mnesia.delete({__MODULE__, id})
        end
      end

      def get_by_id(id) do
        transact do
          case :mnesia.read(__MODULE__, id) do
            [] -> {:error, :entry_not_found}
            [found] -> {:ok, found |> Entry.from_tuple}
          end
        end
      end

      def enqueue(%Entry{} = ent) do
        transact do
          new_entry =
            ent
            |> Entry.put_queue(__MODULE__)
          new_entry
            |> Entry.to_tuple
            |> :mnesia.write
          new_entry
        end
      end

      @doc """
      apparently :mnesia.clear_table/1 uses it's own transaction
      even though the docs do not mention this fact at all. ffs.
      """
      def clear do
        case :mnesia.clear_table(__MODULE__) do
          {:aborted, _} = aborted -> aborted
          {:atomic, :ok} -> :ok
        end
      end

      def list do
        do_list_queue()
        |> Enum.map(fn tup -> Entry.from_tuple(tup) end)
      end

      defp do_list_queue do
        transact do
          :mnesia.foldl(fn (item, acc) -> [item | acc] end, [], __MODULE__)
        end
      end

      def expired do
        now = SolidQueue.Timestamp.now()
        expired_match_spec = [{{:_, :"$1",  :_, :_, :"$2"}, [{:<, :"$2", now}], [:"$1"]}]
        transact do
          :mnesia.select(__MODULE__, expired_match_spec)
        end
      end

    end
  end

end