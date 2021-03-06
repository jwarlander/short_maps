defmodule ShortMapsTest do
  use ExUnit.Case, async: true
  import ShortMaps

  test "uses the bindings from the current environment" do
    foo = 1
    assert ~m(foo)a == %{foo: 1}
  end

  test "can be used in regular matches" do
    assert ~m(foo)a = %{foo: "bar"}
    foo # this removes the "variable foo is unused" warning
  end

  test "when used in pattern matches, it binds variables in the scope" do
    ~m(foo)a = %{foo: "bar"}
    assert foo == "bar"
  end

  test "pin syntax in pattern matches will match on same value" do
    foo = "bar"
    assert ~m(^foo)a = %{foo: "bar"}
  end

  test "pin syntax in pattern matches will raise if no match" do
    msg = "no match of right hand side value: %{foo: \"baaz\"}"
    assert_raise MatchError, msg, fn ->
      foo = "bar"
      ~m(^foo)a = %{foo: "baaz"}
    end
  end

  test "can be used in function heads for anonymoys functions" do
    fun = fn
      ~m(foo)a -> foo
      _       -> :no_match
    end

    assert fun.(%{foo: "bar"}) == "bar"
    assert fun.(%{baz: "bong"}) == :no_match
  end

  test "can be used in function heads for functions in modules" do
    defmodule FunctionHead do
      def test(~m(foo)a), do: foo
      def test(_),       do: :no_match
    end

    assert FunctionHead.test(%{foo: "bar"}) == "bar"
    assert FunctionHead.test(%{baz: "bong"}) == :no_match
  end

  test "supports atom keys with the 'a' modifier" do
    assert ~m(foo bar)a = %{foo: "foo", bar: "bar"}
    assert {foo, bar} == {"foo", "bar"}
  end

  test "supports string keys with the 's' modifier" do
    assert ~m(foo bar)s = %{"foo" => "hello", "bar" => "world"}
    assert {foo, bar} == {"hello", "world"}
  end

  test "wrong modifiers raise an ArgumentError" do
    code = quote do: ~m(foo)k
    msg = "only these modifiers are supported: s, a"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end

  test "no interpolation is supported" do
    code = quote do: ~m(foo #{bar} baz)a
    msg = "interpolation is not supported with the ~m sigil"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end

  defmodule Foo do
    defstruct bar: nil
  end

  test "supports structs" do
    bar = 1
    assert ~m(%Foo bar)a == %Foo{bar: 1}
  end

  test "struct syntax can be used in regular matches" do
    assert ~m(%Foo bar)a = %Foo{bar: "123"}
    bar # this removes the "variable bar is unused" warning
  end

  test "when using structs, fails on non-existing keys" do
    code = quote do: ~m(%Foo bar baaz)a = %Foo{bar: 1}
    msg = ~r/unknown key :baaz for struct ShortMapsTest.Foo/
    assert_raise CompileError, msg, fn ->
      Code.eval_quoted(code, [], __ENV__)
    end
  end

  test "when using structs, only accepts 'a' modifier" do
    code = quote do
      bar = 5
      ~m(%Foo bar)s
    end
    msg = "structs can only consist of atom keys"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end
end
