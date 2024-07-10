import gleam/dict
import gleam/list
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/ctx_utils
import handles/internal/parser

type Action {
  Append(String)
  SetCtx(ctx.Value)
  Continue(List(parser.AST))
  Stop(error.RuntimeError)
}

pub fn eval(
  actions: List(Action),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
  builder: string_builder.StringBuilder,
) -> Result(string_builder.StringBuilder, error.RuntimeError) {
  case actions {
    [] -> Ok(builder)
    [Stop(err), ..] -> Error(err)
    [Append(value), ..rest_action] ->
      eval(rest_action, ctx, partials, string_builder.append(builder, value))
    [SetCtx(ctx), ..rest_action] -> eval(rest_action, ctx, partials, builder)
    [Continue([]), ..rest_action] -> eval(rest_action, ctx, partials, builder)
    [Continue([parser.Constant(_, value), ..rest_ast]), ..rest_action] ->
      eval(
        [Append(value), Continue(rest_ast), ..rest_action],
        ctx,
        partials,
        builder,
      )
    [Continue([parser.Property(index, path), ..rest_ast]), ..rest_action] ->
      case ctx_utils.get_property(path, ctx, index) {
        Ok(str) ->
          eval(
            [Append(str), Continue(rest_ast), ..rest_action],
            ctx,
            partials,
            builder,
          )
        Error(err) -> eval([Stop(err)], ctx, partials, builder)
      }
    [Continue([parser.Partial(index, id, path), ..rest_ast]), ..rest_action] ->
      case dict.get(partials, id) {
        Error(_) ->
          eval([Stop(error.UnknownPartial(index, id))], ctx, partials, builder)
        Ok(partial) ->
          case ctx_utils.get(path, ctx, index) {
            Error(err) -> eval([Stop(err)], ctx, partials, builder)
            Ok(new_ctx) ->
              eval(
                [
                  SetCtx(new_ctx),
                  Continue(partial),
                  SetCtx(ctx),
                  Continue(rest_ast),
                  ..rest_action
                ],
                ctx,
                partials,
                builder,
              )
          }
      }
    [
      Continue([parser.IfBlock(index, path, children), ..rest_ast]),
      ..rest_action
    ] ->
      case ctx_utils.get_bool(path, ctx, index) {
        Error(err) -> eval([Stop(err)], ctx, partials, builder)
        Ok(False) ->
          eval([Continue(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(True) ->
          eval(
            [Continue(children), Continue(rest_ast), ..rest_action],
            ctx,
            partials,
            builder,
          )
      }
    [
      Continue([parser.UnlessBlock(index, path, children), ..rest_ast]),
      ..rest_action
    ] ->
      case ctx_utils.get_bool(path, ctx, index) {
        Error(err) -> eval([Stop(err)], ctx, partials, builder)
        Ok(True) ->
          eval([Continue(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(False) ->
          eval(
            [Continue(children), Continue(rest_ast), ..rest_action],
            ctx,
            partials,
            builder,
          )
      }
    [
      Continue([parser.EachBlock(index, path, children), ..rest_ast]),
      ..rest_action
    ] ->
      case ctx_utils.get_list(path, ctx, index) {
        Error(err) -> eval([Stop(err)], ctx, partials, builder)
        Ok([]) ->
          eval([Continue(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(ctxs) ->
          eval(
            ctxs
              |> list.flat_map(fn(new_ctx) {
                [SetCtx(new_ctx), Continue(children), SetCtx(ctx)]
              })
              |> list.append([Continue(rest_ast), ..rest_action]),
            ctx,
            partials,
            builder,
          )
      }
  }
}

pub fn run(
  ast: List(parser.AST),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
  builder: string_builder.StringBuilder,
) -> Result(string_builder.StringBuilder, error.RuntimeError) {
  eval([Continue(ast)], ctx, partials, builder)
}
