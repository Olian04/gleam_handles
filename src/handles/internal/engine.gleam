import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string_builder
import handles/ctx
import handles/error
import handles/internal/parser

fn drill_ctx(
  path: List(String),
  ctx: ctx.Value,
) -> Result(ctx.Value, error.RuntimeError) {
  case path {
    [] -> Ok(ctx)
    [key, ..rest] ->
      case ctx {
        ctx.Dict(arr) -> {
          case list.find(arr, fn(it) { it.key == key }) {
            Ok(ctx.Prop(_, value)) -> drill_ctx(rest, value)
            Error(_) -> Error(error.UnknownPropertyError([]))
          }
        }
        ctx.List(_) -> Error(error.UnexpectedTypeError([], "List", ["Dict"]))
        ctx.Str(_) -> Error(error.UnexpectedTypeError([], "Str", ["Dict"]))
        ctx.Int(_) -> Error(error.UnexpectedTypeError([], "Int", ["Dict"]))
        ctx.Float(_) -> Error(error.UnexpectedTypeError([], "Float", ["Dict"]))
        ctx.Bool(_) -> Error(error.UnexpectedTypeError([], "Bool", ["Dict"]))
      }
  }
}

fn get_property(
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(String, error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, got, expected) ->
        error.UnexpectedTypeError(path, got, expected)
      error.UnknownPropertyError(_) -> error.UnknownPropertyError(path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.Str(value) -> value |> Ok
      ctx.Int(value) -> value |> int.to_string |> Ok
      ctx.Float(value) -> value |> float.to_string |> Ok
      ctx.List(_) ->
        Error(error.UnexpectedTypeError(path, "List", ["Str", "Int", "Float"]))
      ctx.Dict(_) ->
        Error(error.UnexpectedTypeError(path, "Dict", ["Str", "Int", "Float"]))
      ctx.Bool(_) ->
        Error(error.UnexpectedTypeError(path, "Bool", ["Str", "Int", "Float"]))
    }
  })
}

fn get_list(
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(List(ctx.Value), error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, got, expected) ->
        error.UnexpectedTypeError(path, got, expected)
      error.UnknownPropertyError(_) -> error.UnknownPropertyError(path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.List(value) -> value |> Ok
      ctx.Bool(_) -> Error(error.UnexpectedTypeError(path, "Bool", ["List"]))
      ctx.Str(_) -> Error(error.UnexpectedTypeError(path, "Str", ["List"]))
      ctx.Int(_) -> Error(error.UnexpectedTypeError(path, "Int", ["List"]))
      ctx.Float(_) -> Error(error.UnexpectedTypeError(path, "Float", ["List"]))
      ctx.Dict(_) -> Error(error.UnexpectedTypeError(path, "Dict", ["List"]))
    }
  })
}

fn get_bool(
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(Bool, error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, got, expected) ->
        error.UnexpectedTypeError(path, got, expected)
      error.UnknownPropertyError(_) -> error.UnknownPropertyError(path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.Bool(value) -> value |> Ok
      ctx.List(_) -> Error(error.UnexpectedTypeError(path, "List", ["Bool"]))
      ctx.Str(_) -> Error(error.UnexpectedTypeError(path, "Str", ["Bool"]))
      ctx.Int(_) -> Error(error.UnexpectedTypeError(path, "Int", ["Bool"]))
      ctx.Float(_) -> Error(error.UnexpectedTypeError(path, "Float", ["Bool"]))
      ctx.Dict(_) -> Error(error.UnexpectedTypeError(path, "Dict", ["Bool"]))
    }
  })
}

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

pub fn run(
  ast: List(parser.AST),
  ctx: ctx.Value,
  builder: string_builder.StringBuilder,
) -> Result(String, error.RuntimeError) {
  case ast {
    [] -> builder |> string_builder.to_string |> Ok
    [node, ..rest] ->
      case node {
        parser.Constant(value) ->
          run(
            rest,
            ctx,
            builder
              |> string_builder.append(value),
          )
        parser.Property(path) ->
          get_property(path, ctx)
          |> result.try(fn(it) {
            run(
              rest,
              ctx,
              builder
                |> string_builder.append(it),
            )
          })
        parser.IfBlock(path, children) ->
          get_bool(path, ctx)
          |> result.try(fn(it) {
            case it {
              False -> run(rest, ctx, builder)
              True ->
                run(children, ctx, string_builder.new())
                |> result.try(fn(it) {
                  run(
                    rest,
                    ctx,
                    builder
                      |> string_builder.append(it),
                  )
                })
            }
          })
        parser.UnlessBlock(path, children) ->
          get_bool(path, ctx)
          |> result.try(fn(it) {
            case it {
              True -> run(rest, ctx, builder)
              False ->
                run(children, ctx, string_builder.new())
                |> result.try(fn(it) {
                  run(
                    rest,
                    ctx,
                    builder
                      |> string_builder.append(it),
                  )
                })
            }
          })
        parser.EachBlock(path, children) ->
          get_list(path, ctx)
          |> result.try(run_each(_, children, string_builder.new()))
      }
  }
}
