import gleam/bool
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string_builder
import handles/parser

pub type RuntimeError {
  UnexpectedTypeError(path: List(String), got: String, expected: List(String))
  UnknownPropertyError(path: List(String))
}

fn get_from_ctx(
  root_ctx: dynamic.Dynamic,
  path: List(String),
) -> Result(dynamic.Dynamic, RuntimeError) {
  path
  |> list.fold(Ok(root_ctx), fn(ctx, it) {
    use ctx <- result.try(ctx)
    ctx
    |> dynamic.field(it, dynamic.dynamic)
    |> result.map_error(fn(_) { UnknownPropertyError(path) })
  })
}

pub fn get_as_string(
  root_ctx: dynamic.Dynamic,
  path: List(String),
) -> Result(String, RuntimeError) {
  get_from_ctx(root_ctx, path)
  |> result.try(fn(value) {
    case dynamic.classify(value) {
      "String" ->
        value
        |> dynamic.string
        |> result.map_error(fn(err) {
          io.debug(err)
          panic as "TypeConvertionError"
        })

      "Int" ->
        value
        |> dynamic.int
        |> result.map(int.to_string)
        |> result.map_error(fn(err) {
          io.debug(err)
          panic as "TypeConvertionError"
        })

      "Float" ->
        value
        |> dynamic.float
        |> result.map(float.to_string)
        |> result.map_error(fn(err) {
          io.debug(err)
          panic as "TypeConvertionError"
        })

      typ -> Error(UnexpectedTypeError(path, typ, ["String", "Int", "Float"]))
    }
  })
}

pub fn get_as_bool(
  root_ctx: dynamic.Dynamic,
  path: List(String),
) -> Result(Bool, RuntimeError) {
  get_from_ctx(root_ctx, path)
  |> result.try(fn(value) {
    case dynamic.classify(value) {
      "Bool" ->
        value
        |> dynamic.bool
        |> result.map_error(fn(err) {
          io.debug(err)
          panic as "TypeConvertionError"
        })

      typ -> Error(UnexpectedTypeError(path, typ, ["Bool"]))
    }
  })
}

pub fn get_as_list(
  root_ctx: dynamic.Dynamic,
  path: List(String),
) -> Result(List(dynamic.Dynamic), RuntimeError) {
  get_from_ctx(root_ctx, path)
  |> result.try(fn(value) {
    case dynamic.classify(value) {
      "List" ->
        value
        |> dynamic.shallow_list
        |> result.map_error(fn(err) {
          io.debug(err)
          panic as "TypeConvertionError"
        })

      typ -> Error(UnexpectedTypeError(path, typ, ["List"]))
    }
  })
}

fn eval_if(
  condition: Bool,
  children: List(parser.AST),
  ctx: dynamic.Dynamic,
) -> Result(String, RuntimeError) {
  case condition {
    False -> Ok("")
    True -> run(children, ctx)
  }
}

fn eval_each(
  ctx_list: List(dynamic.Dynamic),
  children: List(parser.AST),
) -> Result(String, RuntimeError) {
  {
    use acc, ctx <- list.fold(ctx_list, Ok(string_builder.new()))
    use acc <- result.try(acc)
    run(children, ctx)
    |> result.map(string_builder.append(acc, _))
  }
  |> result.map(string_builder.to_string)
}

pub fn run(
  ast: List(parser.AST),
  ctx: dynamic.Dynamic,
) -> Result(String, RuntimeError) {
  {
    use acc, it <- list.fold(ast, Ok(string_builder.new()))
    use acc <- result.try(acc)
    case it {
      parser.Constant(value) -> Ok(string_builder.append(acc, value))
      parser.Property(path) ->
        get_as_string(ctx, path)
        |> result.map(string_builder.append(acc, _))
      parser.Block(kind, path, children) ->
        case kind {
          "if" ->
            get_as_bool(ctx, path)
            |> result.try(eval_if(_, children, ctx))
            |> result.map(string_builder.append(acc, _))

          "unless" ->
            get_as_bool(ctx, path)
            |> result.map(bool.negate)
            |> result.try(eval_if(_, children, ctx))
            |> result.map(string_builder.append(acc, _))

          "each" ->
            get_as_list(ctx, path)
            |> result.try(eval_each(_, children))
            |> result.map(string_builder.append(acc, _))

          _ -> panic as "Unknown block"
        }
    }
  }
  |> result.map(string_builder.to_string)
}
