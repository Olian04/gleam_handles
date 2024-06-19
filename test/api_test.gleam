import gleeunit/should
import handles
import handles/ctx

pub fn api_hello_world_test() {
  handles.prepare("Hello {{name}}!")
  |> should.be_ok
  |> handles.run(ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))]))
  |> should.be_ok
  |> should.equal("Hello Oliver!")
}

pub fn api_knattarna_test() {
  handles.prepare("{{#each knattarna}}Hello {{name}}\n{{/each}}")
  |> should.be_ok
  |> handles.run(
    ctx.Dict([
      ctx.Prop(
        "knattarna",
        ctx.List([
          ctx.Dict([ctx.Prop("name", ctx.Str("Knatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Fnatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Tjatte"))]),
        ]),
      ),
    ]),
  )
  |> should.be_ok
  |> should.equal(
    "Hello Knatte
Hello Fnatte
Hello Tjatte
",
  )
}
