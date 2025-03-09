import gleam/string_tree
import gleeunit/should
import handles
import handles/ctx

pub fn property_string_test() {
  handles.prepare("Hello {{name}}!")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))]), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello Oliver!")
}

pub fn property_int_test() {
  handles.prepare("The answer is {{answer}}!")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("answer", ctx.Int(42))]), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("The answer is 42!")
}

pub fn property_float_test() {
  handles.prepare("π = {{pi}}!")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("pi", ctx.Float(3.14))]), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("π = 3.14!")
}
