defmodule Pokemometro do
  @url "https://pokeapi.co/api/v2/pokemon/ditto"
  @moduledoc """
  Documentation for `Pokemometro`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Pokemometro.hello()
      :world

  """
  def get_pokemon do
    HTTPoison.get(@url)
    |> format_data
  end


  def format_data({:ok, %HTTPoison.Response{status_code: 200, body: data}}) do
    {:ok, Poison.decode(data)}
  end

  def format_data({:ok, %HTTPoison.Response{status_code: _, body: data}}) do
    {:erro, data}
  end

  def format_data({:erro, r}), do: {:erro, r}

end
