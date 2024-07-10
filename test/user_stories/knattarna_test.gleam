import gleam/dict
import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const input_template = "They are {{#each knattarna}}{{name}}, {{/each}}and Kalle"

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

const expected_tokens = [
  tokenizer.Constant(0, "They are "),
  tokenizer.EachBlockStart(11, ["knattarna"]), tokenizer.Property(30, ["name"]),
  tokenizer.Constant(36, ", "), tokenizer.EachBlockEnd(40),
  tokenizer.Constant(47, "and Kalle"),
]

const expected_ast = [
  parser.Constant(0, "They are "),
  parser.EachBlock(
    11,
    ["knattarna"],
    [parser.Property(30, ["name"]), parser.Constant(36, ", ")],
  ), parser.Constant(47, "and Kalle"),
]

const expected_output = "They are Knatte, Fnatte, Tjatte, and Kalle"

pub fn tokenizer_test() {
  tokenizer.run(input_template, 0, [])
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_test() {
  parser.run(expected_tokens, [])
  |> should.equal(expected_ast)
}

pub fn engine_test() {
  engine.run(expected_ast, input_context, dict.new(), string_builder.new())
  |> should.be_ok
  |> string_builder.to_string
  |> should.equal(expected_output)
}
