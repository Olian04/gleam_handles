import gleam/dynamic
import gleam/result
import handles/engine
import handles/lexer
import handles/parser

pub type HandlesError {
  LexError(error: lexer.LexError)
  ParseError(error: List(parser.ParseError))
  RuntimeError(error: engine.RuntimeError)
}

pub type Template {
  Template(ast: List(parser.AST))
}

pub fn prepare(template: String) -> Result(Template, HandlesError) {
  use tokens <- result.try(result.map_error(lexer.run(template), LexError))
  use ast <- result.try(
    result.map_error(parser.run(tokens, ["if", "unless", "each"]), fn(err) {
      ParseError(err)
    }),
  )
  Ok(Template(ast))
}

pub fn run(
  template: Template,
  ctx: dynamic.Dynamic,
) -> Result(String, HandlesError) {
  let Template(ast) = template
  engine.run(ast, ctx)
  |> result.map_error(RuntimeError)
}
