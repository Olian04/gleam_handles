import compiler
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/string_builder

pub type RuntimeError {
  UnableToResolveExpression(expression: String)
  UnknownBlock(kind: String)
}

fn dynamic_to_string(value: dynamic.Dynamic) -> String {
  case dynamic.classify(value) {
    "Nil" -> "Nil"
    "Null" -> "Nil"
    "String" -> {
      let assert Ok(val) = value |> dynamic.string
      val
    }
    "Int" -> {
      let assert Ok(val) = value |> dynamic.int
      int.to_string(val)
    }
    "Float" -> {
      let assert Ok(val) = value |> dynamic.float
      float.to_string(val)
    }
    "Bool" -> {
      let assert Ok(val) = value |> dynamic.bool
      bool.to_string(val)
    }
    "List" -> {
      let assert Ok(val) =
        value
        |> dynamic.list(fn(it) { Ok(dynamic_to_string(it)) })

      val
      |> list.fold(string_builder.new(), fn(acc, it) {
        string_builder.append(acc, "\"")
        string_builder.append(acc, it)
        string_builder.append(acc, "\", ")
      })
      |> string_builder.to_string
      |> string.drop_right(string.length(", "))
    }
    "Dict" -> {
      let assert Ok(val) =
        value
        |> dynamic.dict(dynamic.string, fn(it) { Ok(dynamic_to_string(it)) })

      val
      |> dict.to_list
      |> list.fold(string_builder.new(), fn(acc, it) {
        string_builder.append(acc, "\"")
        string_builder.append(acc, it.0)
        string_builder.append(acc, "\"=\"")
        string_builder.append(acc, it.1)
        string_builder.append(acc, "\", ")
      })
      |> string_builder.to_string
      |> string.drop_right(string.length(", "))
    }
    _ -> ""
  }
}

pub fn get_as_string(root_ctx: dynamic.Dynamic, path: List(String)) -> String {
  path
  |> list.fold(root_ctx, fn(ctx, it) {
    let assert Ok(value) = dynamic.field(it, dynamic.dynamic)(ctx)
    value
  })
  |> dynamic_to_string
}

pub fn get_as_bool(root_ctx: dynamic.Dynamic, path: List(String)) -> Bool {
  path
  |> list.fold(root_ctx, fn(ctx, it) {
    let assert Ok(value) = dynamic.field(it, dynamic.dynamic)(ctx)
    value
  })
  |> dynamic.bool
  |> result.unwrap(False)
}

pub fn get_as_list(
  root_ctx: dynamic.Dynamic,
  path: List(String),
) -> List(dynamic.Dynamic) {
  path
  |> list.fold(root_ctx, fn(ctx, it) {
    let assert Ok(value) = dynamic.field(it, dynamic.dynamic)(ctx)
    value
  })
  |> dynamic.shallow_list
  |> result.unwrap([])
}

fn eval_if(
  condition: Bool,
  children: List(compiler.AST),
  ctx: dynamic.Dynamic,
) -> String {
  case condition {
    False -> ""
    True -> run(children, ctx)
  }
}

fn eval_each(
  ctx_list: List(dynamic.Dynamic),
  children: List(compiler.AST),
) -> String {
  ctx_list
  |> list.fold(string_builder.new(), fn(acc, ctx) {
    string_builder.append(acc, run(children, ctx))
  })
  |> string_builder.to_string
}

pub fn run(ast: List(compiler.AST), ctx: dynamic.Dynamic) -> String {
  {
    use acc, it <- list.fold(ast, string_builder.new())
    case it {
      compiler.Constant(value) -> string_builder.append(acc, value)
      compiler.Property(path) ->
        string_builder.append(acc, get_as_string(ctx, path))
      compiler.Block(kind, path, children) ->
        case kind {
          "if" ->
            string_builder.append(
              acc,
              get_as_bool(ctx, path)
                |> eval_if(children, ctx),
            )
          "unless" ->
            string_builder.append(
              acc,
              get_as_bool(ctx, path)
                |> bool.negate
                |> eval_if(children, ctx),
            )
          "each" ->
            string_builder.append(
              acc,
              get_as_list(ctx, path)
                |> eval_each(children),
            )
          _ -> panic as "Unknown block"
        }
    }
  }
  |> string_builder.to_string
}
