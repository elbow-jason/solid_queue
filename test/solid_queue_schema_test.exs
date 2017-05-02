defmodule SolidQueueSchemaExample do
  require SolidQueue.Schema
  import SolidQueue.Schema

  schema :person do
    field :name,    :string, default: ""
    field :age,     :integer, default: 0
    field :gender,  :string
  end

end

defmodule SolidQueueSchemaTest do
  use ExUnit.Case
  doctest SolidQueue.Schema

  test "fields defined in schema show up in @fields attr" do
    result = SolidQueueSchemaExample.__schema__(:fields)
    # the order matters.
    expected = [
      %SolidQueue.Field{name: :name,    opts: [default: ""],  type: :string},
      %SolidQueue.Field{name: :age,     opts: [default: 0],  type: :integer},
      %SolidQueue.Field{name: :gender,  opts: [],             type: :string},
    ]
    assert result |> is_list
    assert result === expected
  end

  test "fields defined in schema appear in the struct" do
    model = %SolidQueueSchemaExample{}
    assert Map.has_key?(model, :name)
    assert Map.has_key?(model, :age)
  end

  test "defaults for fields appear in the struct" do
    model = %SolidQueueSchemaExample{}
    assert model.name === ""
    assert model.age === 0
    assert model.gender === nil
  end

  test "to_tuple works" do
    model = %SolidQueueSchemaExample{
      name: "beef",
      age:  1,
      gender: "female",
    }
    assert SolidQueueSchemaExample.to_tuple(model) === {:person, "beef", 1, "female"}
  end

end
