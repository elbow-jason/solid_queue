defmodule SolidQueue.Error do

  defstruct [
    payload:    nil,
    reason:     nil,
    errored_at: nil,
  ]

  def new(payload, reason) do
    %SolidQueue.Error{
      payload:    payload,
      reason:     reason,
      errored_at: SolidQueue.Timestamp.now(),
    }
  end

end