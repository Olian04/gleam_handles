import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const input_template = "Hello {{name}}!"

const input_context = ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))])

const expected_tokens = [
  tokenizer.Constant("Hello "), tokenizer.Property(["name"]),
  tokenizer.Constant("!"),
]

const expected_ast = [
  parser.Constant("Hello "), parser.Property(["name"]), parser.Constant("!"),
]

const expected_output = "Hello Oliver!"

pub fn tokenizer_should_return_correct_for_user_story_helloworld_test() {
  tokenizer.run(input_template, 0, [])
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_should_return_correct_for_user_story_helloworld_test() {
  parser.run(expected_tokens, [])
  |> should.equal(expected_ast)
}

pub fn engine_should_return_correct_for_user_story_helloworld_test() {
  engine.run(expected_ast, input_context, string_builder.new())
  |> should.be_ok
  |> should.equal(expected_output)
}
