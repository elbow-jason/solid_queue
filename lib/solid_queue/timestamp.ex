defmodule SolidQueue.Timestamp do
  
  def now() do
    DateTime.utc_now |> DateTime.to_unix
  end

end