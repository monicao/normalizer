defmodule Normalizer do
  import Inflector, only: [pluralize: 1]

  @moduledoc """
  Takes in a nested Map (Maps and Lists).
  Returns a normalized list of values in the format:
    {
    pluralized_key: [...maps for this key...]
    }
  Responsibilities:
  - The list of maps is uniq'd to remove duplicates.
  - Validates that all maps have an id key
  """

  defmodule InvalidMapStructure do
    defexception message: "The map given to normalize_map! is invalid. Ensure each map has an id field."
  end

  def normalize_map!(map) when is_map(map) do
    parent_map = Enum.reduce(map, %{}, fn({key, value}, acc) ->
      value
        |> process_value(key, %{})
        |> Enum.reduce(acc, fn({top_key, top_value}, acc2) ->
          Map.put(acc2, top_key, top_value)
        end)
    end)

    remove_duplicates(parent_map)
  end
  def normalize_map!(map) do
    raise InvalidMapStructure, message: "normalize_map!(map) must take in a map as a parameter but got #{inspect(map)}"
  end

  defp process_value(map, key, parent_map) when is_map(map) do
    # Process the plain values: Strings, Integers, etc. Not maps or lists
    plain_value_map = Enum.reduce(map, %{}, fn({inner_key, inner_value}, acc) ->
      if !is_list(inner_value) && !is_map(inner_value) do
        Map.put(acc, inner_key, inner_value)
      else
        acc
      end
    end)
    require_ids!(plain_value_map, key)
    result_without_nested_keys = add_to_normalized_map(parent_map, pluralize(key), plain_value_map)
    # Process the 'nested' values: maps or lists
    nested_keys = Map.keys(map) -- Map.keys(plain_value_map)
    result_with_nested_keys = Enum.reduce(nested_keys, result_without_nested_keys, fn(key, acc) ->
      process_value(map[key], key, acc)
    end)
    result_with_nested_keys
  end
  # process_value([%{id: 1, name: "Foo"}], "user", %{}])
  # Returns: %{users: [%{id: 1, name: "Foo"}]}
  defp process_value(list, key, parent_map) when is_list(list) do
    res = Enum.reduce(list, parent_map, fn(map, current_normalized_map) ->
      process_value(map, pluralize(key), current_normalized_map)
    end)
    res
  end

  defp add_to_normalized_map(parent_map, pluralized_key, map) do
    if !Map.has_key?(parent_map, pluralized_key) do
      Map.put(parent_map, pluralized_key, [map])
    else
      Map.put(parent_map, pluralized_key, parent_map[pluralized_key] ++ [map])
    end
  end

  defp remove_duplicates(parent_map) do
    Enum.reduce(parent_map, %{}, fn({key, value}, acc) ->
      Map.put(acc, key, Enum.uniq(value))
    end)
  end

  defp require_ids!(map, key) when is_map(map) do
    unless Map.has_key?(map, :id) do
      raise InvalidMapStructure, message: "Map is missing the id key. %{#{key}: #{inspect(map)}}"
    end
    map
  end
end

