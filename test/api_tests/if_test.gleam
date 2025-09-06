import gleam/string_tree
import gleeunit/should
import handles
import handles/ctx

pub fn if_truthy_test() {
  handles.prepare("{{#if prop}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Bool(True))]), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("yes")
}

pub fn if_falsy_test() {
  handles.prepare("{{#if prop}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Bool(False))]), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("")
}

pub fn if_current_context_test() {
  handles.prepare("{{#if .}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(ctx.Bool(True), [])
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("yes")
}
