import gleam/dict
import gleam/string_tree
import gleeunit/should
import handles/ctx
import handles/internal/block
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
  tokenizer.BlockStart(11, block.Each, ["knattarna"]),
  tokenizer.Property(30, ["name"]),
  tokenizer.Constant(36, ", "),
  tokenizer.BlockEnd(40, block.Each),
  tokenizer.Constant(47, "and Kalle"),
]

const expected_ast = [
  parser.Constant(0, "They are "),
  parser.Block(
    11,
    40,
    block.Each,
    ["knattarna"],
    [parser.Property(30, ["name"]), parser.Constant(36, ", ")],
  ),
  parser.Constant(47, "and Kalle"),
]

const expected_output = "They are Knatte, Fnatte, Tjatte, and Kalle"

pub fn tokenizer_test() {
  tokenizer.run(input_template)
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_test() {
  parser.run(expected_tokens)
  |> should.be_ok
  |> should.equal(expected_ast)
}

pub fn engine_test() {
  engine.run(expected_ast, input_context, dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal(expected_output)
}
