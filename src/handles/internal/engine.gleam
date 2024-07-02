import gleam/bool
import gleam/dict
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
  partials: dict.Dict(String, List(parser.AST)),
) -> Result(String, error.RuntimeError) {
  case ctxs {
    [] -> builder |> string_builder.to_string |> Ok
    [ctx, ..rest] ->
      run(ast, ctx, partials, string_builder.new())
      |> result.try(fn(it) {
        run_each(rest, ast, builder |> string_builder.append(it), partials)
      })
  }
}

fn run_if(
  bool: Bool,
  children: List(parser.AST),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
) -> Result(String, error.RuntimeError) {
  case bool {
    False -> Ok("")
    True -> run(children, ctx, partials, string_builder.new())
  }
}

pub fn run(
  ast: List(parser.AST),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
  builder: string_builder.StringBuilder,
) -> Result(String, error.RuntimeError) {
  case ast {
    [] -> builder |> string_builder.to_string |> Ok
    [node, ..rest] ->
      case node {
        parser.Constant(_, value) -> Ok(value)
        parser.Property(index, path) -> ctx_utils.get_property(path, ctx, index)
        parser.Partial(index, id, path) ->
          case dict.get(partials, id) {
            Error(_) -> Error(error.UnknownPartial(index, id))
            Ok(partial) ->
              ctx_utils.get(path, ctx, index)
              |> result.try(run(partial, _, partials, string_builder.new()))
          }

        parser.IfBlock(index, path, children) ->
          ctx_utils.get_bool(path, ctx, index)
          |> result.try(run_if(_, children, ctx, partials))
        parser.UnlessBlock(index, path, children) ->
          ctx_utils.get_bool(path, ctx, index)
          |> result.map(bool.negate)
          |> result.try(run_if(_, children, ctx, partials))
        parser.EachBlock(index, path, children) ->
          ctx_utils.get_list(path, ctx, index)
          |> result.try(run_each(_, children, string_builder.new(), partials))
      }
      |> result.try(fn(it) {
        run(
          rest,
          ctx,
          partials,
          builder
            |> string_builder.append(it),
        )
      })
  }
}
