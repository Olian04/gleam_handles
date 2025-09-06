import gleam/string_tree
import gleeunit/should
import handles
import handles/ctx

pub fn partial_test() {
  let hello_template =
    handles.prepare("Hello {{.}}!")
    |> should.be_ok

  handles.prepare("{{>hello prop}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Str("Oliver"))]), [
    #("hello", hello_template),
  ])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello Oliver!")
}

pub fn partial_multiple_test() {
  let hello_template =
    handles.prepare("Hello {{.}}!")
    |> should.be_ok

  handles.prepare("{{>hello prop_a}} {{>hello prop_b}} {{>hello prop_c}}")
  |> should.be_ok
  |> handles.run(
    ctx.Dict([
      ctx.Prop("prop_a", ctx.Str("Knatte")),
      ctx.Prop("prop_b", ctx.Str("Fnatte")),
      ctx.Prop("prop_c", ctx.Str("Tjatte")),
    ]),
    [#("hello", hello_template)],
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello Knatte! Hello Fnatte! Hello Tjatte!")
}

pub fn partial_nested_test() {
  let exclaim_template =
    handles.prepare("{{.}}!")
    |> should.be_ok

  let hello_template =
    handles.prepare("Hello {{>exclaim .}}")
    |> should.be_ok

  handles.prepare("{{>hello prop}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Str("Oliver"))]), [
    #("hello", hello_template),
    #("exclaim", exclaim_template),
  ])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello Oliver!")
}
