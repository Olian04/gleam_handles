import compiler
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/result
import gleam/string_builder

pub type RuntimeError {
  UnableToResolveExpression(expression: String)
  UnknownBlock(kind: String)
}

pub type ExpressionType {
  StringType
  BoolType
  ListType
}

pub fn run(
  ast: List(compiler.AST),
  resolve_expression: fn(String, ExpressionType) -> Result(dynamic.Dynamic, Nil),
) -> Result(String, List(RuntimeError)) {
  case
    ast
    |> list.fold(#(string_builder.new(), []), fn(acc, it) {
      case it {
        compiler.Constant(value) -> #(
          string_builder.append(acc.0, value),
          acc.1,
        )
        compiler.Expression(expression) ->
          case
            resolve_expression(expression, StringType)
            |> result.try(fn(it) {
              it
              |> dynamic.string
              |> result.nil_error
            })
          {
            Ok(value) -> #(string_builder.append(acc.0, value), acc.1)
            Error(_) -> #(acc.0, [
              UnableToResolveExpression(expression),
              ..acc.1
            ])
          }
        compiler.Block(kind, "", _) -> #(acc.0, [UnknownBlock(kind), ..acc.1])
        compiler.Block(kind, expression, children) ->
          case kind {
            "if" ->
              case
                resolve_expression(expression, BoolType)
                |> result.try(fn(it) {
                  it
                  |> dynamic.bool
                  |> result.nil_error
                })
              {
                Ok(True) ->
                  case run(children, resolve_expression) {
                    Ok(str) -> #(string_builder.append(acc.0, str), acc.1)
                    Error(_) -> #(acc.0, [
                      UnableToResolveExpression(expression),
                      ..acc.1
                    ])
                  }
                Ok(False) -> acc
                Error(_) -> #(acc.0, [
                  UnableToResolveExpression(expression),
                  ..acc.1
                ])
              }
            "unless" ->
              case
                resolve_expression(expression, BoolType)
                |> result.try(fn(it) {
                  it
                  |> dynamic.bool
                  |> result.nil_error
                })
              {
                Ok(False) ->
                  case run(children, resolve_expression) {
                    Ok(str) -> #(string_builder.append(acc.0, str), acc.1)
                    Error(_) -> #(acc.0, [
                      UnableToResolveExpression(expression),
                      ..acc.1
                    ])
                  }
                Ok(True) -> acc
                Error(_) -> #(acc.0, [
                  UnableToResolveExpression(expression),
                  ..acc.1
                ])
              }
            "each" -> todo
            _ -> #(acc.0, [UnknownBlock(kind), ..acc.1])
          }
      }
    })
  {
    #(ok, []) -> Ok(string_builder.to_string(ok))
    #(_, err) -> Error(list.reverse(err))
  }
}
