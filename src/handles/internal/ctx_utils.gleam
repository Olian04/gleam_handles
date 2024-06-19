import gleam/float
import gleam/int
import gleam/list
import gleam/result
import handles/ctx
import handles/error

pub fn drill_ctx(
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
            Error(_) -> Error(error.UnknownPropertyError(0, []))
          }
        }
        ctx.List(_) -> Error(error.UnexpectedTypeError(0, [], "List", ["Dict"]))
        ctx.Str(_) -> Error(error.UnexpectedTypeError(0, [], "Str", ["Dict"]))
        ctx.Int(_) -> Error(error.UnexpectedTypeError(0, [], "Int", ["Dict"]))
        ctx.Float(_) ->
          Error(error.UnexpectedTypeError(0, [], "Float", ["Dict"]))
        ctx.Bool(_) -> Error(error.UnexpectedTypeError(0, [], "Bool", ["Dict"]))
      }
  }
}

pub fn get_property(
  index: Int,
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(String, error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, _, got, expected) ->
        error.UnexpectedTypeError(index, path, got, expected)
      error.UnknownPropertyError(_, _) ->
        error.UnknownPropertyError(index, path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.Str(value) -> value |> Ok
      ctx.Int(value) -> value |> int.to_string |> Ok
      ctx.Float(value) -> value |> float.to_string |> Ok
      ctx.List(_) ->
        Error(
          error.UnexpectedTypeError(index, path, "List", ["Str", "Int", "Float"]),
        )
      ctx.Dict(_) ->
        Error(
          error.UnexpectedTypeError(index, path, "Dict", ["Str", "Int", "Float"]),
        )
      ctx.Bool(_) ->
        Error(
          error.UnexpectedTypeError(index, path, "Bool", ["Str", "Int", "Float"]),
        )
    }
  })
}

pub fn get_list(
  index: Int,
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(List(ctx.Value), error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, _, got, expected) ->
        error.UnexpectedTypeError(index, path, got, expected)
      error.UnknownPropertyError(_, _) ->
        error.UnknownPropertyError(index, path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.List(value) -> value |> Ok
      ctx.Bool(_) ->
        Error(error.UnexpectedTypeError(index, path, "Bool", ["List"]))
      ctx.Str(_) ->
        Error(error.UnexpectedTypeError(index, path, "Str", ["List"]))
      ctx.Int(_) ->
        Error(error.UnexpectedTypeError(index, path, "Int", ["List"]))
      ctx.Float(_) ->
        Error(error.UnexpectedTypeError(index, path, "Float", ["List"]))
      ctx.Dict(_) ->
        Error(error.UnexpectedTypeError(index, path, "Dict", ["List"]))
    }
  })
}

pub fn get_bool(
  index: Int,
  path: List(String),
  root_ctx: ctx.Value,
) -> Result(Bool, error.RuntimeError) {
  drill_ctx(path, root_ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedTypeError(_, _, got, expected) ->
        error.UnexpectedTypeError(index, path, got, expected)
      error.UnknownPropertyError(_, _) ->
        error.UnknownPropertyError(index, path)
    }
  })
  |> result.try(fn(it) {
    case it {
      ctx.Bool(value) -> value |> Ok
      ctx.List(_) ->
        Error(error.UnexpectedTypeError(index, path, "List", ["Bool"]))
      ctx.Str(_) ->
        Error(error.UnexpectedTypeError(index, path, "Str", ["Bool"]))
      ctx.Int(_) ->
        Error(error.UnexpectedTypeError(index, path, "Int", ["Bool"]))
      ctx.Float(_) ->
        Error(error.UnexpectedTypeError(index, path, "Float", ["Bool"]))
      ctx.Dict(_) ->
        Error(error.UnexpectedTypeError(index, path, "Dict", ["Bool"]))
    }
  })
}
