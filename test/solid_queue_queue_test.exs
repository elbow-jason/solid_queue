defmodule SolidQueueQueueExample do
  use SolidQueue.Queue, name: :test_queue_01
end

defmodule SolidQueueQueueTest do
  use ExUnit.Case
  doctest SolidQueue.Queue

  test "__MODULE__.Entry submodule is loaded" do
    assert Code.ensure_loaded?(SolidQueueQueueExample.Entry)
  end

  test "__MODULE__.Entry is configured correctly" do
    model = %SolidQueueQueueExample.Entry{}
    assert Map.has_key?(model, :id)
    assert Map.has_key?(model, :timestamp)
    assert Map.has_key?(model, :payload)
  end

  test "__MODULE__.Entry to_tuple works" do
    model = %SolidQueueQueueExample.Entry{id: 123, timestamp: 456, payload: %{
      something: :to_store,
    }}
    assert SolidQueueQueueExample.Entry.to_tuple(model) == {:test_queue_01, 123, 456, %{something: :to_store}}
  end


end