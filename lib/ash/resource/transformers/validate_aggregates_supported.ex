defmodule Ash.Resource.Transformers.ValidateAggregatesSupported do
  @moduledoc """
  Confirms that all aggregates are supported by the data layer
  """
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  def after_compile?, do: true

  def transform(dsl_state) do
    resource = Transformer.get_persisted(dsl_state, :module)

    dsl_state
    |> Transformer.get_entities([:aggregates])
    |> Enum.each(fn %{relationship_path: relationship_path, name: name} ->
      check_aggregatable(resource, resource, name, relationship_path)
    end)

    {:ok, dsl_state}
  end

  defp check_aggregatable(_resource, _root_resource, _name, []), do: :ok

  defp check_aggregatable(resource, root_resource, name, [relationship | rest]) do
    relationship = Ash.Resource.Info.relationship(resource, relationship)

    if Ash.DataLayer.data_layer_can?(
         resource,
         {:aggregate_relationship, relationship}
       ) do
      check_aggregatable(relationship.destination, root_resource, name, rest)
    else
      raise DslError,
        module: root_resource,
        message: "#{inspect(resource)}.#{relationship.name} is not aggregatable",
        path: [:aggregates, name]
    end
  end
end