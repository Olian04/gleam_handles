import gleeunit/should
import handles
import handles/ctx

pub fn unless_truthy_test() {
  handles.prepare("{{#unless prop}}yes{{/unless}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Bool(True))]))
  |> should.be_ok
  |> should.equal("")
}

pub fn unless_falsy_test() {
  handles.prepare("{{#unless prop}}yes{{/unless}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.Bool(False))]))
  |> should.be_ok
  |> should.equal("yes")
}

pub fn unless_current_context_test() {
  handles.prepare("{{#unless .}}yes{{/unless}}")
  |> should.be_ok
  |> handles.run(ctx.Bool(False))
  |> should.be_ok
  |> should.equal("yes")
}
