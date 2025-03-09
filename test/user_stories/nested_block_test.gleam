import gleam/dict
import gleam/string_tree
import gleeunit/should
import handles/ctx
import handles/internal/block
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
  tokenizer.BlockStart(2, block.Each, ["outer"]),
  tokenizer.BlockStart(17, block.Each, ["inner"]),
  tokenizer.Property(32, ["value"]),
  tokenizer.BlockEnd(41, block.Each),
  tokenizer.BlockEnd(50, block.Each),
]

const expected_ast = [
  parser.Block(
    2,
    50,
    block.Each,
    ["outer"],
    [
      parser.Block(
        17,
        41,
        block.Each,
        ["inner"],
        [parser.Property(32, ["value"])],
      ),
    ],
  ),
]

const expected_output = "1212"

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
