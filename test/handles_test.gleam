import compiler
import engine
import gleam/result
import gleeunit
import gleeunit/should
import parser

pub fn main() {
  gleeunit.main()
}

pub fn handles_hello_world_test() {
  use res <- result.map(parser.parse("Hello World"))
  use tokens <- result.map(res)
  use ast <- result.map(compiler.compile(tokens, []))
  use str <- result.map(engine.run(ast, fn(_, _) { Error(Nil) }))
  should.equal(str, "Hello World")
}
