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
  tokenizer.Constant("They are "), tokenizer.EachBlockStart(["knattarna"]),
  tokenizer.Property(["name"]), tokenizer.Constant(", "), tokenizer.EachBlockEnd,
  tokenizer.Constant("and Kalle"),
]

const expected_ast = [
  parser.Constant("They are "),
  parser.EachBlock(
    ["knattarna"],
    [parser.Property(["name"]), parser.Constant(", ")],
  ), parser.Constant("and Kalle"),
]

const expected_output = "They are Knatte, Fnatte, Tjatte, and Kalle"

pub fn tokenizer_should_return_correct_for_user_story_knattarna_test() {
  tokenizer.run(input_template, 0, [])
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_should_return_correct_for_user_story_knattarna_test() {
  parser.run(expected_tokens, [])
  |> should.equal(expected_ast)
}

pub fn engine_should_return_correct_for_user_story_knattarna_test() {
  engine.run(expected_ast, input_context, string_builder.new())
  |> should.be_ok
  |> should.equal(expected_output)
}
