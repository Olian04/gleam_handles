import gleam/list
import gleam/string
import handles/error

pub type Token {
  Constant(index: Int, value: String)
  Property(index: Int, path: List(String))
  Partial(index: Int, id: String, path: List(String))
  IfBlockStart(index: Int, path: List(String))
  IfBlockEnd(index: Int)
  UnlessBlockStart(index: Int, path: List(String))
  UnlessBlockEnd(index: Int)
  EachBlockStart(index: Int, path: List(String))
  EachBlockEnd(index: Int)
}

fn split_body(body: String) -> List(String) {
  body
  |> string.trim
  |> string.split(" ")
  |> list.filter(fn(it) {
    it
    |> string.trim
    |> string.length
    > 0
  })
}

pub fn run(
  input: String,
  index: Int,
  tokens: List(Token),
) -> Result(List(Token), error.TokenizerError) {
  case input {
    "{{>" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> Error(error.MissingPartialId(index + 2))
            [id, arg] ->
              case arg |> string.trim |> string.split(".") {
                [""] -> Error(error.MissingArgument(index + 2))
                path -> {
                  let path = case path {
                    ["", ""] -> []
                    path -> path
                  }

                  run(
                    rest,
                    index + string.length("{{>}}") + string.length(body),
                    [Partial(index + 2, id, path), ..tokens],
                  )
                }
              }
            _ -> Error(error.UnexpectedMultipleArguments(index + 2))
          }
        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    "{{#" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> Error(error.MissingBlockKind(index + 2))
            [_] -> Error(error.MissingArgument(index + 2))
            [kind, arg] ->
              case arg |> string.trim |> string.split(".") {
                [""] -> Error(error.MissingArgument(index + 2))
                path -> {
                  let path = case path {
                    ["", ""] -> []
                    path -> path
                  }

                  case kind {
                    "if" ->
                      run(
                        rest,
                        index + string.length("{{#}}") + string.length(body),
                        [IfBlockStart(index + 2, path), ..tokens],
                      )
                    "unless" ->
                      run(
                        rest,
                        index + string.length("{{#}}") + string.length(body),
                        [UnlessBlockStart(index + 2, path), ..tokens],
                      )
                    "each" ->
                      run(
                        rest,
                        index + string.length("{{#}}") + string.length(body),
                        [EachBlockStart(index + 2, path), ..tokens],
                      )
                    _ -> Error(error.UnexpectedBlockKind(index))
                  }
                }
              }
            _ -> Error(error.UnexpectedMultipleArguments(index + 2))
          }
        _ -> Error(error.UnbalancedTag(index + 2))
      }

    "{{/" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> Error(error.MissingBlockKind(index + 2))
            [_, _] -> Error(error.UnexpectedArgument(index + 2))
            [kind] ->
              case kind {
                "if" ->
                  run(
                    rest,
                    index + string.length("{{/}}") + string.length(body),
                    [IfBlockEnd(index + 2), ..tokens],
                  )
                "unless" ->
                  run(
                    rest,
                    index + string.length("{{/}}") + string.length(body),
                    [UnlessBlockEnd(index + 2), ..tokens],
                  )
                "each" ->
                  run(
                    rest,
                    index + string.length("{{/}}") + string.length(body),
                    [EachBlockEnd(index + 2), ..tokens],
                  )
                _ -> Error(error.UnexpectedBlockKind(index))
              }
            _ -> Error(error.UnexpectedArgument(index + 2))
          }
        _ -> Error(error.UnbalancedTag(index + 2))
      }

    "{{" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> Error(error.MissingArgument(index + 2))
            [arg] ->
              case arg |> string.split(".") {
                [""] -> Error(error.MissingArgument(index + 2))
                path -> {
                  let path = case path {
                    ["", ""] -> []
                    path -> path
                  }

                  run(
                    rest,
                    index + string.length("{{}}") + string.length(body),
                    [Property(index + 2, path), ..tokens],
                  )
                }
              }
            _ -> Error(error.UnexpectedMultipleArguments(index + 2))
          }
        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    _ ->
      case input |> string.split_once("{{") {
        Ok(#(str, rest)) ->
          run("{{" <> rest, index + string.length(str), [
            Constant(index, str),
            ..tokens
          ])
        _ ->
          case input {
            "" -> Ok(list.reverse(tokens))
            str -> Ok(list.reverse([Constant(index, str), ..tokens]))
          }
      }
  }
}
