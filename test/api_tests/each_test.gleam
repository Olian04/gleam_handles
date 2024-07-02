import gleeunit/should
import handles
import handles/ctx

pub fn each_test() {
  handles.prepare("{{#each prop}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(
    ctx.Dict([ctx.Prop("prop", ctx.List([ctx.Int(1), ctx.Int(2), ctx.Int(3)]))]),
    [],
  )
  |> should.be_ok
  |> should.equal("yesyesyes")
}

pub fn each_empty_test() {
  handles.prepare("{{#each prop}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("prop", ctx.List([]))]), [])
  |> should.be_ok
  |> should.equal("")
}

pub fn each_current_context_test() {
  handles.prepare("{{#each .}}yes{{/if}}")
  |> should.be_ok
  |> handles.run(ctx.List([ctx.Int(1), ctx.Int(2), ctx.Int(3)]), [])
  |> should.be_ok
  |> should.equal("yesyesyes")
}
