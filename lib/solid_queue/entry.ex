defmodule SolidQueue.Entry do

  defstruct [:id, :queue, :payload, :timestamp, :expires]

  def put_queue(%__MODULE__{} = model, queue) do
    %{ model | queue: queue }
  end

  def to_tuple(%__MODULE__{} = model) do
    [
      model.queue,
      model.id,
      model.payload,
      model.timestamp,
      model.expires,
    ]
    |> List.to_tuple
  end

  def from_tuple({queue, id, payload, timestamp, expires}) do
    %__MODULE__{
      queue:      queue,
      id:         id,
      payload:    payload,
      timestamp:  timestamp,
      expires:    expires
    }
  end

end
