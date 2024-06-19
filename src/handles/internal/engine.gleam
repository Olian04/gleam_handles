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
        parser.Constant(_, value) -> Ok(value)
        parser.Property(index, path) -> ctx_utils.get_property(index, path, ctx)
        parser.IfBlock(index, path, children) ->
          ctx_utils.get_bool(index, path, ctx)
          |> result.try(run_if(_, children, ctx))
        parser.UnlessBlock(index, path, children) ->
          ctx_utils.get_bool(index, path, ctx)
          |> result.map(bool.negate)
          |> result.try(run_if(_, children, ctx))
        parser.EachBlock(index, path, children) ->
          ctx_utils.get_list(index, path, ctx)
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
