defmodule SolidQueue.Schema do

  def start_mnesia() do
    :mnesia.start()
  end

  def create_schema(nodes) when is_list(nodes) do
    case :mnesia.create_schema(nodes) do
      {:error, {_, {:already_exists, _}}} -> :ok
      :ok -> :ok
    end
  end

  def migrate_queue(nodes, table_name) when is_list(nodes) do
    create_table(table_name, [
      type: :ordered_set,
      disc_copies: nodes,
      attributes: [:id, :payload, :timestamp, :expires],
    ])
  end

  def migrate_status(nodes) when is_list(nodes) do
    create_table(SolidQueue.Status, [
      type: :set,
      disc_copies: nodes,
      attributes: [:queue_name, :running?, :suspended?],
    ])
  end

  def migrate_counter(nodes) when is_list(nodes) do
    create_table(SolidQueue.Counter, [
      type: :set,
      disc_copies: nodes,
      attributes: [:name, :counter],
    ])
  end

  def create_table(table_name, params) do
    case :mnesia.create_table(table_name, params) do
      {:atomic, :ok} ->
        :ok
      {:aborted, {:already_exists, ^table_name}} ->
        :ok
    end
  end

  def wait_for_tables(tables, timeout \\ 5000) do
    :mnesia.wait_for_tables(tables, timeout)
  end

end