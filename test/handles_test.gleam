import compiler
import engine
import gleam/dict
import gleam/dynamic
import gleam/result
import gleeunit
import gleeunit/should
import parser

pub fn main() {
  gleeunit.main()
}

pub fn handles_hello_world_test() {
  use res <- result.map(parser.parse("Hello {{name}}"))
  use tokens <- result.map(res)
  use ast <- result.map(compiler.compile(tokens, []))
  engine.run(
    ast,
    dict.new()
      |> dict.insert("name", "World")
      |> dynamic.from,
  )
  |> should.equal("Hello World")
}
