import gleam/dict
import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const input_template = "Hello {{name}}!"

const input_context = ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))])

const expected_tokens = [
  tokenizer.Constant(0, "Hello "), tokenizer.Property(8, ["name"]),
  tokenizer.Constant(14, "!"),
]

const expected_ast = [
  parser.Constant(0, "Hello "), parser.Property(8, ["name"]),
  parser.Constant(14, "!"),
]

const expected_output = "Hello Oliver!"

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
  |> should.equal(expected_output)
}
