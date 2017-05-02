defmodule SolidQueue.Counter do

  def start() do
    start([node()])
  end
  def start(nodes) when is_list(nodes) do
    with _ <- :ok,
      :ok <- do_create_schema(nodes),
      :ok <- do_start_mnesia(),
      :ok <- do_migrate(nodes)
    do
      :ok
    else
      err -> err
    end
  end

  defp do_create_schema(nodes) when is_list(nodes) do
    case :mnesia.create_schema(nodes) do
      {:error, {_, {:already_exists, _}}} -> :ok
      :ok -> :ok
    end
  end

  defp do_start_mnesia() do
    :mnesia.start()
  end

  defp do_migrate(nodes) when is_list(nodes) do
    params = [
      type: :set,
      disc_copies: nodes,
      attributes: [:name, :counter],
    ]
    case :mnesia.create_table(__MODULE__, params) do
      {:atomic, :ok} ->
        :ok
      {:aborted, {:already_exists, __MODULE__}} ->
        :ok
    end
  end

  def next_id(table_name) do
    :mnesia.dirty_update_counter(__MODULE__, table_name, 1)
  end

  def reset_counter(table_name) do
    :mnesia.transaction(fn -> :mnesia.write({__MODULE__, table_name, 0}) end)
  end

end