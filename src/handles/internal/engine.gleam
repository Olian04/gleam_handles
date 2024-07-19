import gleam/dict
import gleam/list
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/ctx_utils
import handles/internal/parser

type Action {
  SetCtx(ctx.Value)
  RunAst(List(parser.AST))
}

fn eval(
  actions: List(Action),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
  builder: string_builder.StringBuilder,
) -> Result(string_builder.StringBuilder, error.RuntimeError) {
  case actions {
    [] -> Ok(builder)
    [SetCtx(new_ctx), ..rest_action] ->
      eval(rest_action, new_ctx, partials, builder)
    [RunAst([]), ..rest_action] -> eval(rest_action, ctx, partials, builder)
    [RunAst([parser.Constant(_, value), ..rest_ast]), ..rest_action] ->
      eval(
        [RunAst(rest_ast), ..rest_action],
        ctx,
        partials,
        string_builder.append(builder, value),
      )
    [RunAst([parser.Property(index, path), ..rest_ast]), ..rest_action] ->
      case ctx_utils.get_property(path, ctx, index) {
        Error(err) -> Error(err)
        Ok(value) ->
          eval(
            [RunAst(rest_ast), ..rest_action],
            ctx,
            partials,
            string_builder.append(builder, value),
          )
      }
    [RunAst([parser.Partial(index, id, path), ..rest_ast]), ..rest_action] ->
      case dict.get(partials, id) {
        Error(_) -> Error(error.UnknownPartial(index, id))
        Ok(partial_ast) ->
          case ctx_utils.get(path, ctx, index) {
            Error(err) -> Error(err)
            Ok(inner_ctx) ->
              eval(
                [
                  SetCtx(inner_ctx),
                  RunAst(partial_ast),
                  SetCtx(ctx),
                  RunAst(rest_ast),
                  ..rest_action
                ],
                ctx,
                partials,
                builder,
              )
          }
      }
    [RunAst([parser.IfBlock(index, path, children), ..rest_ast]), ..rest_action] ->
      case ctx_utils.get_bool(path, ctx, index) {
        Error(err) -> Error(err)
        Ok(False) ->
          eval([RunAst(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(True) ->
          eval(
            [RunAst(children), RunAst(rest_ast), ..rest_action],
            ctx,
            partials,
            builder,
          )
      }
    [
      RunAst([parser.UnlessBlock(index, path, children), ..rest_ast]),
      ..rest_action
    ] ->
      case ctx_utils.get_bool(path, ctx, index) {
        Error(err) -> Error(err)
        Ok(True) ->
          eval([RunAst(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(False) ->
          eval(
            [RunAst(children), RunAst(rest_ast), ..rest_action],
            ctx,
            partials,
            builder,
          )
      }
    [
      RunAst([parser.EachBlock(index, path, children), ..rest_ast]),
      ..rest_action
    ] ->
      case ctx_utils.get_list(path, ctx, index) {
        Error(err) -> Error(err)
        Ok([]) ->
          eval([RunAst(rest_ast), ..rest_action], ctx, partials, builder)
        Ok(ctxs) ->
          eval(
            ctxs
              |> list.flat_map(fn(new_ctx) {
                [SetCtx(new_ctx), RunAst(children), SetCtx(ctx)]
              })
              |> list.append([RunAst(rest_ast), ..rest_action]),
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
  eval([RunAst(ast)], ctx, partials, builder)
}
