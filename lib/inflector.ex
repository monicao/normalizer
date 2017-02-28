defmodule Inflector do

  def is_plural(word) when is_binary(word) do
    String.ends_with?(word, "s")
  end
  def is_plural(word) when is_atom(word) do
    is_plural(Atom.to_string(word))
  end

  def singularize(str) when is_binary(str) do
    if is_plural(str) do
      String.slice(str, 0..-2)
    else
      str
    end
  end
  def singularize(atom) when is_atom(atom) do
    if is_plural(atom) do
      Atom.to_string(atom)
        |> singularize
        |> String.to_atom
    else
      atom
    end
  end

  def pluralize(str) when is_binary(str) do
    if is_plural(str) do
      str
    else
      str <> "s"
    end
  end
  def pluralize(atom) when is_atom(atom) do
    if is_plural(atom) do
      atom
    else
      str = Atom.to_string(atom)
      str = str <> "s"
      String.to_atom(str)
    end
  end
end

