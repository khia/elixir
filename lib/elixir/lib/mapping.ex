defmodule Mapping do
  @moduledoc """
  Functions to define Elixir mapping types
  """

  @doc """
  Main entry point for mapping definition. It defines a module
  with the given `name` and the fields specified in `values`.
  This is invoked directly by `Kernel.defmapping`, so check it
  for more information and documentation.
  """
  def defmapping(name, values, opts) do
    block = Keyword.get(opts, :do, nil)
    quote do
      defmodule unquote(name) do
        @moduledoc false

        Mapping.deffunctions(unquote(values), __ENV__)
        Mapping.defmacros(unquote(values), __ENV__)
        unquote(block)
      end
    end
  end

  def deffunctions(forward_values, env) do
    reverse_values = lc { k, i } inlist forward_values, do: { i, k }

    forward_escaped = Macro.escape(forward_values)
    reverse_escaped = Macro.escape(reverse_values)

    keys = Macro.escape(lc {k, _} inlist forward_values, do: k)
    values = Macro.escape(lc {_, v} inlist forward_values, do: v)

    quoted_values = lc { k, i } inlist forward_escaped do
      quote do
        defmacro unquote(k)(), do: unquote(i)
      end
    end

    quoted_keys = lc { k, i } inlist forward_escaped do
      quote do
        def __key__(unquote(i)), do: unquote(k)
      end
    end

    quoted_names = lc { k, i } inlist forward_escaped do
      quote do
        def __name__(unquote(i)), do: unquote(atom_to_binary(k))
      end
    end

    quoted = quote do
      unquote(quoted_values)

      @mapping unquote(forward_escaped)

      def __spec__(:name), do: __MODULE__
      def __spec__(:keys), do: unquote(keys)
      def __spec__(:values), do: unquote(values)
      def __spec__(:forward), do: unquote(forward_escaped)
      def __spec__(:reverse), do: unquote(reverse_escaped)

      defmacro __mapping__(:name), do: __MODULE__
      defmacro __mapping__(:keys), do: unquote(keys)
      defmacro __mapping__(:values), do: unquote(values)
      defmacro __mapping__(:forward), do: unquote(forward_escaped)
      defmacro __mapping__(:reverse), do: unquote(reverse_escaped)

      unquote(quoted_keys)

      @doc false
      def __key__(_), do: nil

      unquote(quoted_names)

      @doc false
      def __name__(_), do: nil

    end

    Module.eval_quoted(env.module, quoted, [], env.location)

  end
  def defmacros(forward_values, env) do
    reverse_values = lc { k, i } inlist forward_values, do: { i, k }
    reverse_escaped = Macro.escape(reverse_values)

    quoted = quote do
      @doc """
      Convert given value into key of the element.
      """
      defmacro __convert__(v, opts // [result: :atom]) do
        inline = opts[:inline] || false
        __convert__(__MODULE__, v, opts[:result], inline)
      end

      defp __convert__(module, v, :atom, false) do
         quote do: unquote(module).__key__(unquote(v))
      end
      defp __convert__(module, v, :binary, false) do
         quote do: unquote(module).__name__(unquote(v))
      end
      defp __convert__(_, v, result, true) do
        index = HashDict.new unquote(reverse_escaped)
        key = Dict.get(index, v)
        if result == :binary and not nil?(key) do
          quote do: unquote(atom_to_binary(key))
        else
          quote do: unquote(key)
        end
      end
    end

    Module.eval_quoted(env.module, quoted, [], env.location)
  end
end