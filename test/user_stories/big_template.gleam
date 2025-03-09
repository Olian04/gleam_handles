import gleam/dict
import gleam/yielder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const input_context = ctx.Dict(
  [
    ctx.Prop(
      "knattarna",
      ctx.List(
        [
          ctx.Dict([ctx.Prop("name", ctx.Str("Knatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Fnatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Tjatte"))]),
        ],
      ),
    ),
  ],
)

pub type TestSpec(a) {
  Timeout(Int, fn() -> a)
}

fn generate_template(size: Int, sep: String) {
  yielder.repeat("{{#each knattarna}}{{name}}, {{/each}}")
  |> yielder.take(size)
  |> yielder.fold("", fn(a, b) { a <> sep <> b })
}

pub fn tokenizer_test_() {
  use <- Timeout(10)

  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
}

pub fn parser_test_() {
  use <- Timeout(10)

  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
}

pub fn engine_test_() {
  use <- Timeout(10)

  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
  |> engine.run(input_context, dict.new())
  |> should.be_ok
}
