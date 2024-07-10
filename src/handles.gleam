import gleam/dict
import gleam/result
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

pub opaque type Template {
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
  ctx: ctx.Value,
  partials: List(#(String, Template)),
) -> Result(String, error.RuntimeError) {
  let Template(ast) = template
  let partials_dict =
    partials
    |> dict.from_list
    |> dict.map_values(fn(_, template) {
      let Template(ast) = template
      ast
    })

  engine.run(ast, ctx, partials_dict, string_builder.new())
  |> result.map(string_builder.to_string)
}
