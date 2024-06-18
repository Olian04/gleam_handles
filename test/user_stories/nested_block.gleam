import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const input_template = "{{#each outer}}{{#each inner}}{{value}}{{/each}}{{/each}}"

const input_context = ctx.Dict(
  [
    ctx.Prop(
      "outer",
      ctx.List(
        [
          ctx.Dict(
            [
              ctx.Prop(
                "inner",
                ctx.List(
                  [
                    ctx.Dict([ctx.Prop("value", ctx.Int(1))]),
                    ctx.Dict([ctx.Prop("value", ctx.Int(2))]),
                  ],
                ),
              ),
            ],
          ),
          ctx.Dict(
            [
              ctx.Prop(
                "inner",
                ctx.List(
                  [
                    ctx.Dict([ctx.Prop("value", ctx.Int(1))]),
                    ctx.Dict([ctx.Prop("value", ctx.Int(2))]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ],
)

const expected_tokens = [
  tokenizer.EachBlockStart(["outer"]), tokenizer.EachBlockStart(["inner"]),
  tokenizer.Property(["value"]), tokenizer.EachBlockEnd, tokenizer.EachBlockEnd,
]

const expected_ast = [
  parser.EachBlock(
    ["outer"],
    [parser.EachBlock(["inner"], [parser.Property(["value"])])],
  ),
]

const expected_output = "1212"

pub fn tokenizer_should_return_correct_for_user_story_nested_test() {
  tokenizer.run(input_template, 0, [])
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_should_return_correct_for_user_story_nested_test() {
  parser.run(expected_tokens, [])
  |> should.equal(expected_ast)
}

pub fn engine_should_return_correct_for_user_story_nested_test() {
  engine.run(expected_ast, input_context, string_builder.new())
  |> should.be_ok
  |> should.equal(expected_output)
}
