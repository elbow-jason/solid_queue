defmodule SolidQueue.Cleaner do

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @queue Keyword.get(opts, :queue)
      if is_nil(@queue) do
        raise %ArgumentError{message: "`use SolidQueue.Cleaner` requires a :queue keyword"}
      end
      @interval Keyword.get(opts, :interval, 5000)

      use GenServer

      def start_link() do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end

      def init(_) do
        repeat()
        {:ok, nil}
      end

      def handle_info(:clean, state) do
        @queue.errorize_expired()
        repeat()
        {:noreply, state}
      end

      defp repeat() do
        Process.send_after(self(), :clean, @interval)
      end

    end
  end

end