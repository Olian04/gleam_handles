import gleam/dict
import gleam/list
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/block
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
      [RunAst(rest_ast), ..rest_action]
      |> eval(ctx, partials, string_builder.append(builder, value))
    [RunAst([parser.Property(index, path), ..rest_ast]), ..rest_action] ->
      case ctx_utils.get_property(path, ctx, index) {
        Error(err) -> Error(err)
        Ok(value) ->
          [RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, string_builder.append(builder, value))
      }
    [RunAst([parser.Partial(index, id, path), ..rest_ast]), ..rest_action] ->
      case dict.get(partials, id) {
        Error(_) ->
          error.UnknownPartial(index, id)
          |> Error
        Ok(partial_ast) ->
          case ctx_utils.get(path, ctx, index) {
            Error(err) -> Error(err)
            Ok(inner_ctx) ->
              [
                SetCtx(inner_ctx),
                RunAst(partial_ast),
                SetCtx(ctx),
                RunAst(rest_ast),
                ..rest_action
              ]
              |> eval(ctx, partials, builder)
          }
      }
    [
      RunAst([
        parser.Block(start_index, _, block.If, path, children),
        ..rest_ast
      ]),
      ..rest_action
    ] ->
      case ctx_utils.get_bool(path, ctx, start_index) {
        Error(err) -> Error(err)
        Ok(False) ->
          [RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, builder)
        Ok(True) ->
          [RunAst(children), RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, builder)
      }
    [
      RunAst([
        parser.Block(start_index, _, block.Unless, path, children),
        ..rest_ast
      ]),
      ..rest_action
    ] ->
      case ctx_utils.get_bool(path, ctx, start_index) {
        Error(err) -> Error(err)
        Ok(True) ->
          [RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, builder)
        Ok(False) ->
          [RunAst(children), RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, builder)
      }
    [
      RunAst([
        parser.Block(start_index, _, block.Each, path, children),
        ..rest_ast
      ]),
      ..rest_action
    ] ->
      case ctx_utils.get_list(path, ctx, start_index) {
        Error(err) -> Error(err)
        Ok([]) ->
          [RunAst(rest_ast), ..rest_action]
          |> eval(ctx, partials, builder)
        Ok(ctxs) ->
          ctxs
          |> list.flat_map(fn(new_ctx) { [SetCtx(new_ctx), RunAst(children)] })
          |> list.append([SetCtx(ctx), RunAst(rest_ast), ..rest_action])
          |> eval(ctx, partials, builder)
      }
  }
}

pub fn run(
  ast: List(parser.AST),
  ctx: ctx.Value,
  partials: dict.Dict(String, List(parser.AST)),
) -> Result(string_builder.StringBuilder, error.RuntimeError) {
  eval([RunAst(ast)], ctx, partials, string_builder.new())
}
