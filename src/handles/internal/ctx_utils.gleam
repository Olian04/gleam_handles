import gleam/float
import gleam/int
import gleam/list
import gleam/result
import handles/ctx
import handles/error

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
            Error(_) -> Error(error.UnknownProperty(0, []))
          }
        }
        ctx.List(_) -> Error(error.UnexpectedType(0, [], "List", ["Dict"]))
        ctx.Str(_) -> Error(error.UnexpectedType(0, [], "Str", ["Dict"]))
        ctx.Int(_) -> Error(error.UnexpectedType(0, [], "Int", ["Dict"]))
        ctx.Float(_) -> Error(error.UnexpectedType(0, [], "Float", ["Dict"]))
        ctx.Bool(_) -> Error(error.UnexpectedType(0, [], "Bool", ["Dict"]))
      }
  }
}

pub fn get(path: List(String), ctx: ctx.Value, index: Int) {
  drill_ctx(path, ctx)
  |> result.map_error(fn(err) {
    case err {
      error.UnexpectedType(_, _, got, expected) ->
        error.UnexpectedType(index, path, got, expected)
      error.UnknownProperty(_, _) -> error.UnknownProperty(index, path)
      err -> err
    }
  })
}

pub fn get_property(
  path: List(String),
  root_ctx: ctx.Value,
  index: Int,
) -> Result(String, error.RuntimeError) {
  get(path, root_ctx, index)
  |> result.try(fn(it) {
    case it {
      ctx.Str(value) -> value |> Ok
      ctx.Int(value) -> value |> int.to_string |> Ok
      ctx.Float(value) -> value |> float.to_string |> Ok
      ctx.List(_) ->
        Error(
          error.UnexpectedType(index, path, "List", ["Str", "Int", "Float"]),
        )
      ctx.Dict(_) ->
        Error(
          error.UnexpectedType(index, path, "Dict", ["Str", "Int", "Float"]),
        )
      ctx.Bool(_) ->
        Error(
          error.UnexpectedType(index, path, "Bool", ["Str", "Int", "Float"]),
        )
    }
  })
}

pub fn get_list(
  path: List(String),
  root_ctx: ctx.Value,
  index: Int,
) -> Result(List(ctx.Value), error.RuntimeError) {
  get(path, root_ctx, index)
  |> result.try(fn(it) {
    case it {
      ctx.List(value) -> value |> Ok
      ctx.Bool(_) -> Error(error.UnexpectedType(index, path, "Bool", ["List"]))
      ctx.Str(_) -> Error(error.UnexpectedType(index, path, "Str", ["List"]))
      ctx.Int(_) -> Error(error.UnexpectedType(index, path, "Int", ["List"]))
      ctx.Float(_) ->
        Error(error.UnexpectedType(index, path, "Float", ["List"]))
      ctx.Dict(_) -> Error(error.UnexpectedType(index, path, "Dict", ["List"]))
    }
  })
}

pub fn get_bool(
  path: List(String),
  root_ctx: ctx.Value,
  index: Int,
) -> Result(Bool, error.RuntimeError) {
  get(path, root_ctx, index)
  |> result.try(fn(it) {
    case it {
      ctx.Bool(value) -> value |> Ok
      ctx.List(_) -> Error(error.UnexpectedType(index, path, "List", ["Bool"]))
      ctx.Str(_) -> Error(error.UnexpectedType(index, path, "Str", ["Bool"]))
      ctx.Int(_) -> Error(error.UnexpectedType(index, path, "Int", ["Bool"]))
      ctx.Float(_) ->
        Error(error.UnexpectedType(index, path, "Float", ["Bool"]))
      ctx.Dict(_) -> Error(error.UnexpectedType(index, path, "Dict", ["Bool"]))
    }
  })
}
