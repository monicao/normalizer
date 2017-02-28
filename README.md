# Normalizer

When requesting data from web APIs or doing joins in Ecto, you will have to work with data that is deeply nested.

This package flattens the data into a top-level map.

There are two main requirements:
- Every nested map must have a key called 'id'
- The nested structure must use naive pluralization. To get the plural of a word just append 's' / to get the singular remove an 's'. So the plural of 'city' is 'citys'. You can easily modify this behaviour by changing `inflector.ex`.

### Example

```elixir
data = %{
  user: %{
    id: 1,
    name: "Bob",
    memberships: [
      %{
        id: 1,
        project_id: 9,
        project: %{
          id: 9,
          name: "Bananas",
          type_id: 3,
          type: %{id: 3, label: "active"}
        }
        user_id: 1
      }
    ],
  }
}

normalize_map!(data)

# Returns
# %{
#   users: [%{id: 1, name: "Bob"}],
#   types: [%{id: 3, label: "active"}],
#   memberships: [%{id: 1, project_id: 9, user_id: 1}],
#   projects: [%{id: 9, name: "Bananas", type_id: 3}]
# }
```

## Run the tests with

```
mix test
```

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `normalizer` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:normalizer, "~> 0.1.0"}]
    end
    ```

