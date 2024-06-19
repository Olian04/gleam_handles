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
  tokenizer.EachBlockStart(2, ["outer"]),
  tokenizer.EachBlockStart(17, ["inner"]), tokenizer.Property(32, ["value"]),
  tokenizer.EachBlockEnd(41), tokenizer.EachBlockEnd(50),
]

const expected_ast = [
  parser.EachBlock(
    2,
    ["outer"],
    [parser.EachBlock(17, ["inner"], [parser.Property(32, ["value"])])],
  ),
]

const expected_output = "1212"

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
  engine.run(expected_ast, input_context, string_builder.new())
  |> should.be_ok
  |> should.equal(expected_output)
}
