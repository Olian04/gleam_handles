import gleam/dict
import gleam/dynamic
import gleam/list
import gleeunit/should
import handles/compiler
import handles/engine
import handles/parser

const input_template = "{{#each knattarna}}Hello {{name}}\n{{/each}}"

const expected_tokens = [
  parser.Constant(0, 0, ""), parser.BlockStart(2, 17, "each", ["knattarna"]),
  parser.Constant(19, 25, "Hello "), parser.Property(27, 31, ["name"]),
  parser.Constant(33, 34, "\n"), parser.BlockEnd(36, 41, "each"),
  parser.Constant(43, 43, ""),
]

const expected_ast = [
  compiler.Block(
    "each",
    ["knattarna"],
    [
      compiler.Constant("Hello "), compiler.Property(["name"]),
      compiler.Constant("\n"),
    ],
  ),
]

const expected_output = "Hello Knatte
Hello Fnatte
Hello Tjatte
"

pub fn parser_should_return_correct_for_user_story_knattarna_test() {
  parser.parse(input_template)
  |> should.be_ok
  |> should.equal(expected_tokens)
}

pub fn compiler_should_return_correct_for_user_story_knattarna_test() {
  compiler.compile(expected_tokens, ["each"])
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
