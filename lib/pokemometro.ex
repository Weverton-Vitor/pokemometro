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
  def main(_) do
    get_pokemon("pikachu")
    |> print_pokemon
  end

  def print_pokemon({:ok, pokemon}) do
    IO.puts("---------- " <> String.capitalize(pokemon[:name]) <> " ----------")
    IO.puts("ID        " <> " ::: " <> Integer.to_string(pokemon[:id]))
    IO.puts("Altura (m)" <> " ::: " <> Float.to_string(pokemon[:height]) <> "m")
    IO.puts("Peso (kg) " <> " ::: " <> Float.to_string(pokemon[:weight]) <> "kg")

    IO.puts("--------- Estatísticas --------")
  end

  def get_pokemon(name) do
    HTTPoison.get(@url <> name)
    |> format_data
    |> filter_data

    # |> print_pokemon

    # {:ok, %{}}
  end

  def list2string([], _), do: ""
  def list2string([x | r], sep \\ ", "), do: x <> sep <> list2string(r, sep)

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
       types: format_types(data["types"]),
       evolutions: "sfd"
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
