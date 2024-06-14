import gleam/dict
import gleam/dynamic
import gleam/list
import gleeunit/should
import handles/engine
import handles/lexer
import handles/parser

const input_template = "{{#each knattarna}}Hello {{name}}\n{{/each}}"

const expected_tokens = [
  lexer.Constant(0, 0, ""), lexer.BlockStart(2, 17, "each", ["knattarna"]),
  lexer.Constant(19, 25, "Hello "), lexer.Property(27, 31, ["name"]),
  lexer.Constant(33, 34, "\n"), lexer.BlockEnd(36, 41, "each"),
  lexer.Constant(43, 43, ""),
]

const expected_ast = [
  parser.Block(
    "each",
    ["knattarna"],
    [
      parser.Constant("Hello "), parser.Property(["name"]),
      parser.Constant("\n"),
    ],
  ),
]

const expected_output = "Hello Knatte
Hello Fnatte
Hello Tjatte
"

pub fn lexer_should_return_correct_for_user_story_knattarna_test() {
  lexer.run(input_template)
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn parser_should_return_correct_for_user_story_knattarna_test() {
  parser.run(expected_tokens, ["each"])
  |> should.be_ok
  |> should.equal(expected_ast)
}

pub fn engine_should_return_correct_for_user_story_knattarna_test() {
  engine.run(
    expected_ast,
    dict.new()
      |> dict.insert(
        "knattarna",
        list.new()
          |> list.append([
            dict.new()
              |> dict.insert("name", "Knatte")
              |> dynamic.from,
            dict.new()
              |> dict.insert("name", "Fnatte")
              |> dynamic.from,
            dict.new()
              |> dict.insert("name", "Tjatte")
              |> dynamic.from,
          ])
          |> dynamic.from,
      )
      |> dynamic.from,
  )
  |> should.be_ok
  |> should.equal(expected_output)
}
