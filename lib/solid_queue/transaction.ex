defmodule SolidQueue.Transaction do

  defmacro transact(do: block) do
    quote do
      if :mnesia.is_transaction do
        unquote(block)
      else
        fn ->
          unquote(block)
        end
        |> :mnesia.transaction
        |> SolidQueue.Transaction.remove_atomic
      end
    end
  end

  def remove_atomic({:atomic, thing}) do
    thing
  end
  def remove_atomic(thing) do
    thing
  end

end