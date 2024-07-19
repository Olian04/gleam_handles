import gleam/dict
import gleam/iterator
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

fn generate_template(size: Int, sep: String) {
  iterator.repeat("{{#each knattarna}}{{name}}, {{/each}}")
  |> iterator.take(size)
  |> iterator.fold("", fn(a, b) { a <> sep <> b })
}

pub fn tokenizer_test() {
  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
}

pub fn parser_test() {
  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
}

pub fn engine_test() {
  let big_template = generate_template(10_000, " ")

  tokenizer.run(big_template)
  |> should.be_ok
  |> parser.run
  |> should.be_ok
  |> engine.run(input_context, dict.new())
  |> should.be_ok
}
