defmodule SolidQueue.Status do
  alias SolidQueue.Status
  require SolidQueue.Transaction
  import SolidQueue.Transaction

  defstruct [
    queue_name: nil,
    running?:   true,
    suspended?: false,
  ]

  def to_tuple(%Status{} = status) do
    {Status, status.queue_name, status.running?, status.suspended?}
  end

  def from_tuple({Status, queue_name, running?, suspended?}) do
    %Status{
      queue_name: queue_name,
      running?:   running?,
      suspended?:   suspended?,
    }
  end

  def add_queue(queue_name) do
    transact do
      case get_queue(queue_name) do
        {:error, :status_not_found} ->
          save(%Status{queue_name: queue_name})
        {:ok, %Status{}} ->
          {:error, {:already_exists, queue_name}}
      end
    end
  end

  def get_queue(queue_name) when is_atom(queue_name) do
    transact do
      case :mnesia.read(Status, queue_name) do
        [] -> {:error, :status_not_found}
        [found] -> {:ok, found |> Status.from_tuple}
      end
    end
  end

  def save(%Status{} = status) do
    transact do
      case status |> Status.to_tuple |> :mnesia.write do
        :ok -> {:ok, status}
        err -> err
      end
    end
  end

  def suspend_queue(queue_name) do
    do_set_suspended(queue_name, true)    
  end

  def resume_queue(queue_name) do
    do_set_suspended(queue_name, false)
  end

  def start_running(queue_name) do
    do_set_running(queue_name, true)
  end

  def stop_running(queue_name) do
    do_set_running(queue_name, false)
  end

  defp do_set_running(queue_name, is_running) when is_atom(queue_name) and is_boolean(is_running) do
    transact do
      case get_queue(queue_name) do
        {:ok, status} ->
          save(%{ status | running?: is_running })
        err ->
          err
      end
    end
  end

  defp do_set_suspended(queue_name, susp) when is_atom(queue_name) and is_boolean(susp) do
    transact do
      case get_queue(queue_name) do
        {:ok, status} ->
          save(%{ status | suspended?: susp, running?: !susp })
        err ->
          err
      end
    end
  end

end