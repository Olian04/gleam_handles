import gleam/dict
import gleam/list
import gleam/pair
import gleam/result
import gleam/string_tree
import handles/ctx
import handles/error
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

pub opaque type Template {
  Template(ast: List(parser.AST))
}

fn unwrap_template(template: Template) -> List(parser.AST) {
  let Template(ast) = template
  ast
}

pub fn prepare(template: String) -> Result(Template, error.TokenizerError) {
  tokenizer.run(template)
  |> result.try(parser.run)
  |> result.map(Template)
}

pub fn run(
  template: Template,
  ctx: ctx.Value,
  partials: List(#(String, Template)),
) -> Result(string_tree.StringTree, error.RuntimeError) {
  partials
  |> list.map(pair.map_second(_, unwrap_template))
  |> dict.from_list
  |> engine.run(unwrap_template(template), ctx, _)
}
