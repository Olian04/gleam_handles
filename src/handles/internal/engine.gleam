import gleam/bool
import gleam/result
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/ctx_utils
import handles/internal/parser

fn run_each(
  ctxs: List(ctx.Value),
  ast: List(parser.AST),
  builder: string_builder.StringBuilder,
) -> Result(String, error.RuntimeError) {
  case ctxs {
    [] -> builder |> string_builder.to_string |> Ok
    [ctx, ..rest] ->
      run(ast, ctx, string_builder.new())
      |> result.try(fn(it) {
        run_each(rest, ast, builder |> string_builder.append(it))
      })
  }
}

fn run_if(
  bool: Bool,
  children: List(parser.AST),
  ctx: ctx.Value,
) -> Result(String, error.RuntimeError) {
  case bool {
    False -> Ok("")
    True -> run(children, ctx, string_builder.new())
  }
}

pub fn run(
  ast: List(parser.AST),
  ctx: ctx.Value,
  builder: string_builder.StringBuilder,
) -> Result(String, error.RuntimeError) {
  case ast {
    [] -> builder |> string_builder.to_string |> Ok
    [node, ..rest] ->
      case node {
        parser.Constant(value) -> Ok(value)
        parser.Property(path) -> ctx_utils.get_property(path, ctx)
        parser.IfBlock(path, children) ->
          ctx_utils.get_bool(path, ctx)
          |> result.try(run_if(_, children, ctx))
        parser.UnlessBlock(path, children) ->
          ctx_utils.get_bool(path, ctx)
          |> result.map(bool.negate)
          |> result.try(run_if(_, children, ctx))
        parser.EachBlock(path, children) ->
          ctx_utils.get_list(path, ctx)
          |> result.try(run_each(_, children, string_builder.new()))
      }
      |> result.try(fn(it) {
        run(
          rest,
          ctx,
          builder
            |> string_builder.append(it),
        )
      })
  }
}
