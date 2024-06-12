import compiler
import engine
import gleam/dict
import gleam/dynamic
import gleeunit/should

pub fn engine_should_return_correct_when_running_hello_world_test() {
  engine.run([compiler.Constant("Hello World")], Nil |> dynamic.from)
  |> should.equal("Hello World")
}

pub fn engine_should_return_correct_when_running_hello_name_test() {
  engine.run(
    [compiler.Constant("Hello "), compiler.Property(["name"])],
    dict.new()
      |> dict.insert("name", "Oliver")
      |> dynamic.from,
  )
  |> should.equal("Hello Oliver")
}

pub fn engine_should_return_correct_when_accessing_nested_property_test() {
  engine.run(
    [compiler.Property(["foo", "bar"])],
    dict.new()
      |> dict.insert(
        "foo",
        dict.new()
          |> dict.insert("bar", 42),
      )
      |> dynamic.from,
  )
  |> should.equal("42")
}

pub fn engine_should_return_correct_when_using_truthy_if_test() {
  engine.run(
    [compiler.Block("if", ["bool"], [compiler.Property(["foo", "bar"])])],
    dict.new()
      |> dict.insert(
        "foo",
        dict.new()
          |> dict.insert("bar", 42)
          |> dynamic.from,
      )
      |> dict.insert(
        "bool",
        True
          |> dynamic.from,
      )
      |> dynamic.from,
  )
  |> should.equal("42")
}

pub fn engine_should_return_correct_when_using_falsy_if_test() {
  engine.run(
    [compiler.Block("if", ["bool"], [compiler.Property(["foo", "bar"])])],
    dict.new()
      |> dict.insert(
        "bool",
        False
          |> dynamic.from,
      )
      |> dynamic.from,
  )
  |> should.equal("")
}

pub fn engine_should_return_correct_when_using_truthy_unless_test() {
  engine.run(
    [compiler.Block("unless", ["bool"], [compiler.Property(["foo", "bar"])])],
    dict.new()
      |> dict.insert(
        "bool",
        True
          |> dynamic.from,
      )
      |> dynamic.from,
  )
  |> should.equal("")
}

pub fn engine_should_return_correct_when_using_falsy_unless_test() {
  engine.run(
    [compiler.Block("unless", ["bool"], [compiler.Property(["foo", "bar"])])],
    dict.new()
      |> dict.insert(
        "foo",
        dict.new()
          |> dict.insert("bar", 42)
          |> dynamic.from,
      )
      |> dict.insert(
        "bool",
        False
          |> dynamic.from,
      )
      |> dynamic.from,
  )
  |> should.equal("42")
}
