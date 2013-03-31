Code.require_file "../test_helper.exs", __FILE__

defmapping MappingTest.SomeMap, a: 0, b: "1", c: nil
defmapping MappingTest.WithNoField, []
defmapping MappingTest.MapWithBody, a: 0, b: "1", c: true do
  Enum.map @mapping, fn({k, v}) ->
    def unquote(binary_to_atom("#{k}_test"))(), do: "#{unquote(v)}"
  end

  def name, do: __mapping__(:name)
  def keys, do: __mapping__(:keys)
  def values, do: __mapping__(:values)
  def forward, do: __mapping__(:forward)
  def reverse, do: __mapping__(:reverse)
end

defmodule MappingTest do
  use ExUnit.Case, async: true

  require MappingTest.SomeMap

  test :to_value do
    assert MappingTest.SomeMap.a == 0
    assert MappingTest.SomeMap.b == "1"
    assert MappingTest.SomeMap.c == nil
  end

  test :from_value_to_key do
    assert MappingTest.SomeMap.__convert__(0) == :a
    assert MappingTest.SomeMap.__convert__("1") == :b
    assert MappingTest.SomeMap.__convert__(nil) == :c
    assert MappingTest.SomeMap.__convert__(:unknown) == nil
  end

  test :from_value_to_binary do
    assert MappingTest.SomeMap.__convert__(0, result: :binary) == "a"
    assert MappingTest.SomeMap.__convert__("1", result: :binary) == "b"
    assert MappingTest.SomeMap.__convert__(nil, result: :binary) == "c"
    assert MappingTest.SomeMap.__convert__(:unknown, result: :binary) == nil
  end

  test :from_value_to_key_inline do
    assert MappingTest.SomeMap.__convert__(0, inline: true) == :a
    assert MappingTest.SomeMap.__convert__("1", inline: true) == :b
    assert MappingTest.SomeMap.__convert__(nil, inline: true) == :c
    assert MappingTest.SomeMap.__convert__(:unknown, inline: true) == nil
  end

  test :from_value_to_binary_inline do
    assert MappingTest.SomeMap.__convert__(0, [result: :binary, inline: true]) == "a"
    assert MappingTest.SomeMap.__convert__("1", [result: :binary, inline: true]) == "b"
    assert MappingTest.SomeMap.__convert__(nil, [result: :binary, inline: true]) == "c"
    assert MappingTest.SomeMap.__convert__(:unknown, [result: :binary, inline: true]) == nil
  end

  test :introspection do
    assert MappingTest.SomeMap.__spec__(:name) == MappingTest.SomeMap
    assert MappingTest.SomeMap.__spec__(:keys) == [:a, :b, :c]
    assert MappingTest.SomeMap.__spec__(:values) == [0, "1", nil]
    assert MappingTest.SomeMap.__spec__(:forward) == [a: 0, b: "1", c: nil]
    assert MappingTest.SomeMap.__spec__(:reverse) == [{0, :a}, {"1", :b}, {nil, :c}]
  end

  test :with_body do
    assert MappingTest.MapWithBody.name == MappingTest.MapWithBody.__spec__(:name)
    assert MappingTest.MapWithBody.keys == MappingTest.MapWithBody.__spec__(:keys)
    assert MappingTest.MapWithBody.values == MappingTest.MapWithBody.__spec__(:values)
    assert MappingTest.MapWithBody.forward == MappingTest.MapWithBody.__spec__(:forward)
    assert MappingTest.MapWithBody.reverse == MappingTest.MapWithBody.__spec__(:reverse)
  end

  test :custom_convert do
    assert MappingTest.MapWithBody.a_test == "0"
    assert MappingTest.MapWithBody.b_test == "1"
    assert MappingTest.MapWithBody.c_test == "true"
  end

end
