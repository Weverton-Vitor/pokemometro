defmodule Pokemometro do
  @url "https://pokeapi.co/api/v2/pokemon/"
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

    pokemonStats = "#{String.capitalize(pokemon[:name])}'s Stats:"

    statsLines =
      Enum.map(pokemon[:stats], fn {label, value} ->
        normalized_value = value * 100 / 120
        bar_length = round(normalized_value * 20 / 100)
        bar = String.duplicate("#", bar_length)
        padding_length = max(0, 16 - String.length(label))
        padding = String.duplicate(" ", padding_length)

        "#{String.capitalize(label)}#{padding}: #{bar} (#{value})"
      end)

    longest = longest([idLine | [heightLine | [weightLine | [pokemonStats | statsLines]]]])
    pokemonNameHeader = centralize(" " <> String.capitalize(pokemon[:name]) <> " ", longest, "-")
    statsHeader = centralize(" Estatísticas ", longest, "-")

    IO.puts(longest)
    IO.puts(pokemonNameHeader)
    IO.puts(idLine)
    IO.puts(heightLine)
    IO.puts(weightLine)
    IO.puts(statsHeader)
    IO.puts(pokemonStats)
    IO.puts(Enum.join(statsLines, "\n"))
  end

  def get_pokemon(name) do
    HTTPoison.get(@url <> name)
    |> format_data
    |> filter_data

    # |> print_pokemon

    # {:ok, %{}}
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

  @spec filter_data({:ok, nil | maybe_improper_list() | map()}) ::
          {:ok,
           %{
             evolutions: <<_::24>>,
             height: any(),
             id: any(),
             name: any(),
             stats: any(),
             type: any(),
             weight: any()
           }}
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
