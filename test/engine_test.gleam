import compiler
import engine
import gleam/dynamic
import gleeunit/should

pub fn engine_should_return_correct_when_running_hello_world_test() {
  engine.run([compiler.Constant("Hello World")], fn(_, _) { Error(Nil) })
  |> should.be_ok
  |> should.equal("Hello World")
}

pub fn engine_should_return_correct_when_running_hello_name_test() {
  engine.run(
    [compiler.Constant("Hello "), compiler.Expression("name")],
    fn(path, prop) {
      case path, prop {
        "name", engine.StringType -> Ok("Oliver" |> dynamic.from)
        _, _ -> Error(Nil)
      }
    },
  )
  |> should.be_ok
  |> should.equal("Hello Oliver")
}

pub fn engine_should_return_correct_when_accessing_nested_property_test() {
  engine.run([compiler.Expression("foo.bar")], fn(expression, typ) {
    case expression, typ {
      "foo.bar", engine.StringType -> Ok("42" |> dynamic.from)
      _, _ -> Error(Nil)
    }
  })
  |> should.be_ok
  |> should.equal("42")
}

pub fn engine_should_return_correct_when_using_truthy_if_test() {
  engine.run(
    [compiler.Block("if", "true", [compiler.Expression("foo.bar")])],
    fn(expression, typ) {
      case expression, typ {
        "foo.bar", engine.StringType -> Ok("42" |> dynamic.from)
        "true", engine.BoolType -> Ok(True |> dynamic.from)
        _, _ -> Error(Nil)
      }
    },
  )
  |> should.be_ok
  |> should.equal("42")
}

pub fn engine_should_return_correct_when_using_falsy_if_test() {
  engine.run(
    [compiler.Block("if", "false", [compiler.Expression("foo.bar")])],
    fn(expression, typ) {
      case expression, typ {
        "false", engine.BoolType -> Ok(False |> dynamic.from)
        _, _ -> Error(Nil)
      }
    },
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn engine_should_return_correct_when_using_truthy_unless_test() {
  engine.run(
    [compiler.Block("unless", "true", [compiler.Expression("foo.bar")])],
    fn(expression, typ) {
      case expression, typ {
        "foo.bar", engine.StringType -> Ok("42" |> dynamic.from)
        "true", engine.BoolType -> Ok(True |> dynamic.from)
        _, _ -> Error(Nil)
      }
    },
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn engine_should_return_correct_when_using_falsy_unless_test() {
  engine.run(
    [compiler.Block("unless", "false", [compiler.Expression("foo.bar")])],
    fn(expression, typ) {
      case expression, typ {
        "foo.bar", engine.StringType -> Ok("42" |> dynamic.from)
        "false", engine.BoolType -> Ok(False |> dynamic.from)
        _, _ -> Error(Nil)
      }
    },
  )
  |> should.be_ok
  |> should.equal("42")
}
