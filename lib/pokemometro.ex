defmodule Pokemometro do
  @url "https://pokeapi.co/api/v2/"

  @moduledoc """
  Documentation for `Pokemometro`.
  """

  @doc """
  Função principal que recebe os argumentos da linha de comando e chama as funções necessárias
  para obter e imprimir informações sobre o Pokémon.
  """
  def main(argv) do
    {options, _, _} = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    # Obtém informações do Pokémon e as imprime
    get_pokemon(options[:name])
    |> print_pokemon
  end

  # Função auxiliar para encontrar o comprimento da string mais longa em uma lista de strings
  def longest(strings), do: longest_p(strings, 0)
  defp longest_p([], a), do: a
  defp longest_p([s | strings], a) do
    if String.length(s) > a do
      longest_p(strings, String.length(s))
    else
      longest_p(strings, a)
    end
  end

  # Função para centralizar o texto em uma linha com um certo tamanho
  def centralize(text, size, _) when size < length(text), do: text
  def centralize(text, size, char) do
    remains = size - String.length(text)
    right = div(remains, 2)
    left = remains - right

    String.duplicate(char, left) <> text <> String.duplicate(char, right)
  end

  # Função para imprimir as informações do Pokémon
  @spec print_pokemon({:ok, nil | maybe_improper_list() | map()}) :: :ok
  def print_pokemon({:ok, pokemon}) do
    # Criação de linhas de informações sobre o Pokémon
    idLine = "ID        " <> " ::: " <> Integer.to_string(pokemon[:id])
    heightLine = "Altura (m)" <> " ::: " <> Float.to_string(pokemon[:height]) <> "m"
    weightLine = "Peso (kg) " <> " ::: " <> Float.to_string(pokemon[:weight]) <> "kg"

    # Criação de linhas de estatísticas do Pokémon
    statsLines =
      Enum.map(pokemon[:stats], fn {label, value} ->
        normalized_value = value * 100 / 120
        bar_length = round(normalized_value * 20 / 100)
        bar = String.duplicate("#", bar_length)
        padding_length = max(0, 16 - String.length(label))
        padding = String.duplicate(" ", padding_length)

        "#{String.capitalize(label)}#{padding}: #{bar} (#{value})"
      end)

    # Criação da cadeia de evolução do Pokémon
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

    # Encontra a largura máxima de todas as linhas de informações
    longest =
      longest([
        idLine
        | [heightLine | [weightLine | [chain | statsLines]]]
      ])

    # Cria cabeçalhos centralizados
    pokemonNameHeader = centralize(" " <> String.capitalize(pokemon[:name]) <> " ", longest, "-")
    statsHeader = centralize(" Estatísticas ", longest, "-")
    evolutionHeader = centralize(" Cadeia de Evolução ", longest, "-")

    # Imprime as informações do Pokémon
    IO.puts(pokemonNameHeader)
    IO.puts(idLine)
    IO.puts(heightLine)
    IO.puts(weightLine)
    IO.puts(statsHeader)
    IO.puts(Enum.join(statsLines, "\n"))
    IO.puts(evolutionHeader)
    IO.puts(pokemon[:evolution_chain])
  end

  # Função para obter informações sobre um Pokémon da API
  def get_pokemon(name) do
    # Obtém informações básicas do Pokémon
    {:ok, pokemon} =
      HTTPoison.get(@url <> "pokemon/" <> name)
      |> format_data
      |> filter_data

    # Obtém informações sobre a cadeia de evolução do Pokémon
    evolution_chain = get_evolution_chain(name)

    # Adiciona a cadeia de evolução ao mapa do Pokémon
    {:ok, Map.put(pokemon, :evolution_chain, evolution_chain)}
  end

  # Função para converter a cadeia de evolução em uma lista de nomes de Pokémon
  def chain_to_array([]), do: []
  def chain_to_array(chain) when is_list(chain) do
    [x | r] = chain
    chain_to_array(x) ++ chain_to_array(r)
  end
  def chain_to_array(chain), do: [chain["species"]["name"] | chain_to_array(chain["evolves_to"])]

  # Função para obter informações sobre a cadeia de evolução de um Pokémon da API
  def get_evolution_chain(name) do
    # Obtém informações sobre a espécie do Pokémon
    {:ok, species_data} =
      HTTPoison.get(@url <> "pokemon-species/" <> name)
      |> format_data

    # Obtém informações sobre a cadeia de evolução da espécie
    {:ok, evolution_chain} =
      HTTPoison.get(species_data["evolution_chain"]["url"])
      |> format_data()

    # Converte a cadeia de evolução em uma lista de nomes de Pokémon
    chain_to_array(evolution_chain["chain"])
  end

  # Função para formatar as estatísticas do Pokémon
  def format_stats(obj, []), do: obj
  def format_stats(obj, [stat | stats]) do
    Map.put(obj, stat["stat"]["name"], stat["base_stat"])
    |> format_stats(stats)
  end

  # Função para formatar os tipos de um Pokémon
  def format_types([]), do: []
  def format_types([tt | types]) do
    [tt["type"]["name"] | format_types(types)]
  end

  # Função para filtrar os dados de resposta da API
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

  # Função para formatar os dados de resposta da API
  def format_data({:ok, %HTTPoison.Response{status_code: status_code, body: data}})
      when status_code >= 200 and status_code < 300 do
    Poison.decode(data)
  end
  def format_data({:ok, %HTTPoison.Response{status_code: _, body: data}}) do
    {:erro, data}
  end
  def format_data({:erro, r}), do: {:erro, r}
end
