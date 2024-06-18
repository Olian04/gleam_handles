import gleam/result
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

pub type Template {
  Template(ast: List(parser.AST))
}

pub fn prepare(template: String) -> Result(Template, error.TokenizerError) {
  tokenizer.run(template, 0, [])
  |> result.map(fn(tokens) {
    let ast = parser.run(tokens, [])
    Template(ast)
  })
}

pub fn run(
  template: Template,
  root_ctx: List(ctx.Prop),
) -> Result(String, error.RuntimeError) {
  let Template(ast) = template
  engine.run(ast, ctx.Dict(root_ctx), string_builder.new())
}
