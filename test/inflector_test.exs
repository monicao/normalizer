defmodule InflectorTest do
  use ExUnit.Case
  import Inflector

  test "is_plural" do
    assert is_plural(:horses)
    assert is_plural("horses")
    assert is_plural("mars") # this is a limitation of the algo
    assert !is_plural(:foo)
    assert !is_plural("foo")
  end

  test "singularize" do
    assert singularize("horses") == "horse"
    assert singularize(:horses) == :horse
    assert singularize("crocodile") == "crocodile"
    assert singularize(:crocodile) == :crocodile
  end

  test "pluralize" do
    assert pluralize("horse") == "horses"
    assert pluralize("horses") == "horses"
    assert pluralize(:crocodile) == :crocodiles
    assert pluralize(:crocodiles) == :crocodiles
  end
end

