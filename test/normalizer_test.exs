defmodule Designdrop.NormalizerTest do
  use ExUnit.Case
  doctest Normalizer

  import Normalizer
  alias Normalizer.InvalidMapStructure

  test "normalize_map!/1 processes several top-level key-map pairs" do
    input = %{
      user: %{id: 1, name: "Bob"},
      book: %{id: 1, title: "Hello"}
    }
    expected = %{
      users: [%{id: 1, name: "Bob"}],
      books: [%{id: 1, title: "Hello"}],
    }
    assert expected == normalize_map!(input)
  end

  test "normalize_map!/1 processes map that is already normalized" do
    input = %{users: [%{id: 1, name: "Bob"}]}
    assert input == normalize_map!(input)
  end

  test "normalize_map!/1 adds id to in one-to-one relationship" do
    input = %{
      projects: [
        %{
          id: 9,
          name: "Bananas",
          user_id: 1,
          user: %{id: 1, name: "Bob"}
        }
      ]
    }
    expected = %{
      users: [%{id: 1, name: "Bob"}],
      projects: [%{id: 9, name: "Bananas", user_id: 1}]
    }
    assert expected == normalize_map!(input)
  end

  test "normalize_map!/1 adds id to in one-to-many or many-to-many relationship" do
    input = %{
      projects: [
        %{
          id: 9,
          name: "Bananas",
          users: [
            %{id: 1, name: "Bob", user_id: 9},
            %{id: 2, name: "Ana", user_id: 9},
          ]
        }
      ]
    }
    expected = %{
      users: [%{id: 1, name: "Bob", user_id: 9}, %{id: 2, name: "Ana", user_id: 9}],
      projects: [%{id: 9, name: "Bananas"}]
    }
    assert expected == normalize_map!(input)
  end

  test "normalize_map!/1 processes deeply nested list" do
    input = %{
      user: %{
        id: 1,
        name: "Bob",
        projects: [
          %{
            id: 9,
            name: "Bananas",
            user_id: 1,
            type: %{id: 3, label: "Active", project_id: 9}
          }
        ]
      }
    }
    expected = %{
      users: [%{id: 1, name: "Bob"}],
      types: [%{id: 3, label: "Active", project_id: 9}],
      projects: [%{id: 9, name: "Bananas", user_id: 1}]
    }
    assert expected == normalize_map!(input)
  end

  test "normalize_map!/1 drops duplicate children" do
    input = %{
      city: %{
        id: 1,
        name: "Vancouver",
        users: [
          %{id: 20,
            name: "Ana",
            city_id: 1,
            city: %{id: 1, name: "Vancouver"},
            projects: [%{id: 1, name: "Bananas"}],
            memberships: [%{id: 1, user_id: 20, project_id: 1}],
          },
          %{
            id: 10,
            name: "Bob",
            projects: [%{id: 1, name: "Bananas"}, %{id: 2, name: "Apples"}],
            memberships: [%{id: 2, user_id: 10, project_id: 1}, %{id: 3, user_id: 10, project_id: 2}],
            city_id: 1,
            city: %{id: 1, name: "Vancouver"}
          }
        ]
      }
    }

    expected = %{
      citys: [%{id: 1, name: "Vancouver"}],
      users: [%{id: 20, name: "Ana", city_id: 1}, %{id: 10, name: "Bob", city_id: 1}],
      projects: [%{id: 1, name: "Bananas"}, %{id: 2, name: "Apples"}],
      memberships: [%{id: 1, user_id: 20, project_id: 1}, %{id: 2, user_id: 10, project_id: 1}, %{id: 3, user_id: 10, project_id: 2}]
    }
    assert expected == normalize_map!(input)
  end

  test "normalize_map!/1 handles multiple occurrences of same record at different depths" do
    input = %{
      user: %{
        id: 267,
        email: "daffy@gmail.com",
        username: "daffy",
        projects: [
          %{
            id: 240,
            drops: [],
            name: "Second Project",
            user_id: 267,
            memberships: [
              %{
                id: 187,
                project_id: 240,
                user: %{email: "daffy@gmail.com", id: 267, username: "daffy"},
                user_id: 267
              },
              %{
                id: 188,
                project_id: 240,
                user: %{ email: "bugs@gmail.com", id: 268, username: "bugs.bunny"},
                user_id: 268
              }
            ],
          },
          %{
            id: 239,
            drops: [],
            name: "My Square Redesign",
            user_id: 267,
            memberships: [
              %{
                id: 186,
                project_id: 239,
                user_id: 267,
                user: %{email: "daffy@gmail.com", id: 267, username: "daffy"},
              }
            ],
          }
        ],
      }
    }
    expected = %{
      memberships: [
        %{id: 187, project_id: 240, user_id: 267},
        %{id: 188, project_id: 240, user_id: 268},
        %{id: 186, project_id: 239, user_id: 267}
      ],
      projects: [
        %{id: 240, name: "Second Project", user_id: 267},
        %{id: 239, name: "My Square Redesign", user_id: 267}
       ],
      users: [
        %{email: "daffy@gmail.com", id: 267, username: "daffy"},
        %{email: "bugs@gmail.com", id: 268, username: "bugs.bunny"}
      ]
    }
    actual = normalize_map!(input)
    assert expected[:memberships] == actual[:memberships]
    assert expected[:projects] == actual[:projects]
    assert expected[:users] == actual[:users]
  end

  test "normalize_map!/1 returns error if any of the maps are missing the id key" do
    input = %{user: %{name: "Bob"}}
    assert_raise InvalidMapStructure, "Map is missing the id key. %{user: %{name: \"Bob\"}}", fn -> normalize_map!(input) end
  end

  test "normalize_map!/1 returns error if input is a list" do
    input = [%{name: "Bob"}]
    assert_raise InvalidMapStructure, "normalize_map!(map) must take in a map as a parameter but got [%{name: \"Bob\"}]", fn -> normalize_map!(input) end
  end
end

