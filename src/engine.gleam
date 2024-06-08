import compiler
import gleam/dynamic
import gleam/list
import gleam/string

pub type RuntimeError {
  UnableToResolveProperty(path: List(String))
  UnknownBlock(kind: String)
}

pub fn run(
  ast: List(compiler.AST),
  get_property: fn(List(String)) -> String,
) -> Result(String, List(RuntimeError)) {
  case
    ast
    |> list.fold(#("", []), fn(acc, it) {
      case it {
        compiler.Constant(value) -> #(string.append(acc.0, value), acc.1)
        compiler.Property(path) -> #(
          string.append(acc.0, get_property(path)),
          acc.1,
        )
        compiler.Block(kind, [], _) -> #(
          acc.0,
          list.append(acc.1, [UnknownBlock(kind)]),
        )
        compiler.Block(kind, [path_string, ..], children) ->
          case kind {
            "if" ->
              case
                get_property(string.split(path_string, "."))
                |> dynamic.from
                |> dynamic.bool()
              {
                Ok(True) ->
                  case run(children, get_property) {
                    Ok(str) -> #(string.append(acc.0, str), acc.1)
                    Error(_) -> #(
                      acc.0,
                      list.append(acc.1, [
                        UnableToResolveProperty(string.split(path_string, ".")),
                      ]),
                    )
                  }
                Ok(False) -> acc
                Error(_) -> #(
                  acc.0,
                  list.append(acc.1, [
                    UnableToResolveProperty(string.split(path_string, ".")),
                  ]),
                )
              }
            "unless" ->
              case
                get_property(string.split(path_string, "."))
                |> dynamic.from
                |> dynamic.bool()
              {
                Ok(False) ->
                  case run(children, get_property) {
                    Ok(str) -> #(string.append(acc.0, str), acc.1)
                    Error(_) -> #(
                      acc.0,
                      list.append(acc.1, [
                        UnableToResolveProperty(string.split(path_string, ".")),
                      ]),
                    )
                  }
                Ok(True) -> acc
                Error(_) -> #(
                  acc.0,
                  list.append(acc.1, [
                    UnableToResolveProperty(string.split(path_string, ".")),
                  ]),
                )
              }
            "while" -> todo
            _ -> #(acc.0, list.append(acc.1, [UnknownBlock(kind)]))
          }
      }
    })
  {
    #(ok, []) -> Ok(ok)
    #(_, err) -> Error(err)
  }
}
