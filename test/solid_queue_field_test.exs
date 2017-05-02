defmodule SolidQueueFieldExample do
  require SolidQueue.Field
  import SolidQueue.Field

  field :age, :integer, default: 0

end


defmodule SolidQueueFieldTest do
  use ExUnit.Case
  doctest SolidQueue.Field

  test "@fields attribute is a list" do
    assert is_list(SolidQueueFieldExample.__schema__(:fields))
  end

  test "field adds Field structs to @fields attribute" do
    assert SolidQueueFieldExample.__schema__(:fields) |> List.first === %SolidQueue.Field{
      name: :age,
      type: :integer,
      opts: [default: 0],
    }
  end

end