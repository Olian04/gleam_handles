import gleam/float
import gleam/int
import gleam/list
import gleam/result
import handles/ctx
import handles/error

type DrillError {
  UnknownProperty
  UnexpectedType(String)
}

fn drill_ctx(
  path: List(String),
  ctx: ctx.Value,
) -> Result(ctx.Value, DrillError) {
  case path {
    [] -> Ok(ctx)
    [key, ..rest] ->
      case ctx {
        ctx.Dict(arr) -> {
          case list.find(arr, fn(it) { it.key == key }) {
            Ok(ctx.Prop(_, value)) -> drill_ctx(rest, value)
            Error(_) -> Error(UnknownProperty)
          }
        }
        ctx.List(_) -> Error(UnexpectedType("List"))
        ctx.Str(_) -> Error(UnexpectedType("Str"))
        ctx.Int(_) -> Error(UnexpectedType("Int"))
        ctx.Float(_) -> Error(UnexpectedType("Float"))
        ctx.Bool(_) -> Error(UnexpectedType("Bool"))
      }
  }
}

pub fn get(path: List(String), ctx: ctx.Value, index: Int) {
  drill_ctx(path, ctx)
  |> result.map_error(fn(err) {
    case err {
      UnexpectedType(got) -> error.UnexpectedType(index, path, got, ["Dict"])
      UnknownProperty -> error.UnknownProperty(index, path)
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
        error.UnexpectedType(index, path, "List", ["Str", "Int", "Float"])
        |> Error
      ctx.Dict(_) ->
        error.UnexpectedType(index, path, "Dict", ["Str", "Int", "Float"])
        |> Error
      ctx.Bool(_) ->
        error.UnexpectedType(index, path, "Bool", ["Str", "Int", "Float"])
        |> Error
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
      ctx.Str(_) -> error.UnexpectedType(index, path, "Str", ["List"]) |> Error
      ctx.Int(_) -> error.UnexpectedType(index, path, "Int", ["List"]) |> Error
      ctx.Bool(_) ->
        error.UnexpectedType(index, path, "Bool", ["List"]) |> Error
      ctx.Float(_) ->
        error.UnexpectedType(index, path, "Float", ["List"]) |> Error
      ctx.Dict(_) ->
        error.UnexpectedType(index, path, "Dict", ["List"]) |> Error
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
      ctx.List(_) ->
        error.UnexpectedType(index, path, "List", ["Bool"]) |> Error
      ctx.Str(_) -> error.UnexpectedType(index, path, "Str", ["Bool"]) |> Error
      ctx.Int(_) -> error.UnexpectedType(index, path, "Int", ["Bool"]) |> Error
      ctx.Float(_) ->
        error.UnexpectedType(index, path, "Float", ["Bool"]) |> Error
      ctx.Dict(_) ->
        error.UnexpectedType(index, path, "Dict", ["Bool"]) |> Error
    }
  })
}
