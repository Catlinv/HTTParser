#Small attempt at typecasting
defmodule RequestFormat do
  @derive [Poison.Encoder]
  defstruct [:tasks]
end

#Code from https://rosettacode.org/wiki/Topological_sort#Elixir with slight edits to match format
defmodule Topological do
  def sort(library) do
    g = :digraph.new
    Enum.each(library, fn command ->
      l = command["name"]
      deps = command["requires"]
      :digraph.add_vertex(g,l)           # noop if library already added
      if deps do Enum.each(deps, fn d -> add_dependency(g,l,d) end) end
    end)
    if t = :digraph_utils.topsort(g) do
      taskMap = library |> Enum.reduce(%{}, fn (command, acc) -> Map.put(acc, command["name"], command["command"]) end)
      %RequestFormat{:tasks => Enum.map(t, fn commandName -> %{"name" => commandName, "command" => taskMap[commandName]} end)}
    else
      IO.puts "ERROR: Tasks cannot be executed since there exists a at least one circular dependency"
      Enum.each(:digraph.vertices(g), fn v ->
        if vs = :digraph.get_short_cycle(g,v), do: print_path(vs)
      end)
      :nil
    end
  end
 
  defp print_path(l), do: IO.puts Enum.join(l, " -> ")
 
  defp add_dependency(_g,l,l), do: :ok
  defp add_dependency(g,l,d) do
    :digraph.add_vertex(g,d)   # noop if dependency already added                                                                                                                                                                                                                       
    :digraph.add_edge(g,d,l)   # Dependencies represented as an edge d -> l
  end
end



defmodule Httparser do

  def paserInput(inputText) do
    try do 
      json = Poison.decode!(inputText, as: %RequestFormat{})
      # IO.puts json.tasks
      Topological.sort(json.tasks)
    rescue
      Poison.ParseError -> IO.puts "ERROR: Invalid request format"
      :nil
    end
  end

  def main(args) do
    options = [strict: [i: :string, o: :string]]
    {opts,_,_}= OptionParser.parse(args, options)
    if !opts[:i] do
      IO.puts "ERROR: Please specify input file. (Ex: --i test.txt)"
    else
      case File.read(opts[:i]) do
        {:ok, body}      -> 
          sortedTasks = paserInput(body)
          if sortedTasks do 
            if opts[:o] do
              saveToFile(sortedTasks,opts[:o])
            else
              saveToScript(sortedTasks.tasks)
            end
          end
        {:error, _reason} -> IO.puts "ERROR: Invalid file name"
      end
    end
  end

  defp saveToFile(data,fileName) do 
    {:ok, file} = File.open(fileName, [:write])
    IO.binwrite(file, Poison.encode!(data))
    File.close(file)
  end

  defp saveToScript(data) do 
    {:ok, file} = File.open("bash.sh", [:write])
    IO.binwrite(file, "#!/usr/bin/env bash\n")
    Enum.each(data, fn task -> IO.binwrite(file, task["command"] <> "\n") end)
    File.close(file)
  end
end
