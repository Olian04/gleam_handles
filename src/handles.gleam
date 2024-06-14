import gleam/dynamic
import gleam/result
import handles/compiler
import handles/engine
import handles/parser

pub type TemplateError {
  ParseError(error: parser.ParseError)
  CompileError(error: List(compiler.CompileError))
}

pub type Template {
  Template(ast: List(compiler.AST))
}

pub fn prepare(template: String) -> Result(Template, TemplateError) {
  use tokens <- result.try(
    result.map_error(parser.parse(template), fn(err) { ParseError(err) }),
  )
  use ast <- result.try(
    result.map_error(
      compiler.compile(tokens, ["if", "unless", "each"]),
      fn(err) { CompileError(err) },
    ),
  )
  Ok(Template(ast))
}

pub fn run(
  template: Template,
  ctx: dynamic.Dynamic,
) -> Result(String, engine.RuntimeError) {
  let Template(ast) = template
  engine.run(ast, ctx)
}
