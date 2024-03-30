defmodule Pokemometro do
  @url "https://pokeapi.co/api/v2/"
  @moduledoc """
  Documentation for `Pokemometro`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Pokemometro.hello()
      :world

  """
  def main(argv) do
    {options, _, _} = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    get_pokemon(options[:name])
    |> print_pokemon
  end

  def longest(strings), do: longest_p(strings, 0)
  defp longest_p([], a), do: a

  defp longest_p([s | strings], a) do
    if String.length(s) > a do
      longest_p(strings, String.length(s))
    else
      longest_p(strings, a)
    end
  end

  def centralize(text, size, _) when size < length(text), do: text

  def centralize(text, size, char) do
    remains = size - String.length(text)
    right = div(remains, 2)
    left = remains - right

    String.duplicate(char, left) <> text <> String.duplicate(char, right)
  end

  @spec print_pokemon({:ok, nil | maybe_improper_list() | map()}) :: :ok
  def print_pokemon({:ok, pokemon}) do
    idLine = "ID        " <> " ::: " <> Integer.to_string(pokemon[:id])
    heightLine = "Altura (m)" <> " ::: " <> Float.to_string(pokemon[:height]) <> "m"
    weightLine = "Peso (kg) " <> " ::: " <> Float.to_string(pokemon[:weight]) <> "kg"

    statsLines =
      Enum.map(pokemon[:stats], fn {label, value} ->
        normalized_value = value * 100 / 120
        bar_length = round(normalized_value * 20 / 100)
        bar = String.duplicate("#", bar_length)
        padding_length = max(0, 16 - String.length(label))
        padding = String.duplicate(" ", padding_length)

        "#{String.capitalize(label)}#{padding}: #{bar} (#{value})"
      end)

    chain =
      Enum.reduce(pokemon[:evolution_chain], fn specie, acc ->
        if specie == pokemon[:name] do
          acc <> " | *" <> specie <> "*"
        else
          if(acc == pokemon[:name]) do
            "*" <> acc <> "* | " <> specie
          else
            acc <> " | " <> specie
          end
        end
      end)

    longest =
      longest([
        idLine
        | [heightLine | [weightLine | [chain | statsLines]]]
      ])

    pokemonNameHeader = centralize(" " <> String.capitalize(pokemon[:name]) <> " ", longest, "-")
    statsHeader = centralize(" Estatísticas ", longest, "-")
    evolutionHeader = centralize(" Cadeia de Evolução ", longest, "-")

    IO.puts(pokemonNameHeader)
    IO.puts(idLine)
    IO.puts(heightLine)
    IO.puts(weightLine)
    IO.puts(statsHeader)
    IO.puts(Enum.join(statsLines, "\n"))
    IO.puts(evolutionHeader)
    IO.puts(pokemon[:evolution_chain])
  end

  def get_pokemon(name) do
    {:ok, pokemon} =
      HTTPoison.get(@url <> "pokemon/" <> name)
      |> format_data
      |> filter_data

    evolution_chain = get_evolution_chain(name)

    {:ok, Map.put(pokemon, :evolution_chain, evolution_chain)}
  end

  def chain_to_array([]), do: []

  def chain_to_array(chain) when is_list(chain) do
    [x | r] = chain
    chain_to_array(x) ++ chain_to_array(r)
  end

  def chain_to_array(chain), do: [chain["species"]["name"] | chain_to_array(chain["evolves_to"])]

  def get_evolution_chain(name) do
    {:ok, species_data} =
      HTTPoison.get(@url <> "pokemon-species/" <> name)
      |> format_data

    {:ok, evolution_chain} =
      HTTPoison.get(species_data["evolution_chain"]["url"])
      |> format_data()

    chain_to_array(evolution_chain["chain"])
  end

  def format_stats(obj, []), do: obj

  def format_stats(obj, [stat | stats]) do
    Map.put(obj, stat["stat"]["name"], stat["base_stat"])
    |> format_stats(stats)
  end

  def format_types([]), do: []

  def format_types([tt | types]) do
    [tt["type"]["name"] | format_types(types)]
  end

  def filter_data({:ok, data}) do
    {:ok,
     %{
       id: data["id"],
       name: data["name"],
       height: data["height"] / 10,
       weight: data["weight"] / 10,
       stats: format_stats(%{}, data["stats"]),
       types: format_types(data["types"])
     }}
  end

  def format_data({:ok, %HTTPoison.Response{status_code: status_code, body: data}})
      when status_code >= 200 and status_code < 300 do
    Poison.decode(data)
  end

  def format_data({:ok, %HTTPoison.Response{status_code: _, body: data}}) do
    {:erro, data}
  end

  def format_data({:erro, r}), do: {:erro, r}
end
