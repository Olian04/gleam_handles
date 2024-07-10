import gleam/dict
import gleam/list
import gleam/pair
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

fn unwrap_template(template: Template) -> List(parser.AST) {
  let Template(ast) = template
  ast
}

pub fn prepare(template: String) -> Result(Template, error.TokenizerError) {
  tokenizer.run(template, 0, [])
  |> result.map(parser.run(_, []))
  |> result.map(Template)
}

pub fn run(
  template: Template,
  ctx: ctx.Value,
  partials: List(#(String, Template)),
) -> Result(String, error.RuntimeError) {
  partials
  |> list.map(pair.map_second(_, unwrap_template))
  |> dict.from_list
  |> engine.run(unwrap_template(template), ctx, _, string_builder.new())
  |> result.map(string_builder.to_string)
}
