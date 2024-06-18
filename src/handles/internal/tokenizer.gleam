import gleam/list
import gleam/string
import handles/error

pub type Token {
  Constant(value: String)
  Property(path: List(String))
  IfBlockStart(path: List(String))
  IfBlockEnd
  UnlessBlockStart(path: List(String))
  UnlessBlockEnd
  EachBlockStart(path: List(String))
  EachBlockEnd
}

pub fn run(
  input: String,
  index: Int,
  tokens: List(Token),
) -> Result(List(Token), error.TokenizerError) {
  case input {
    "{{/if" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#("", rest)) -> run(rest, index + 7, [IfBlockEnd, ..tokens])
        _ -> Error(error.UnexpectedBlockArgument(index + 2))
      }
    "{{#if" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(arg, rest)) ->
          case arg |> string.trim |> string.trim |> string.split(".") {
            [""] -> Error(error.MissingBlockArgument(index + 2))
            path ->
              run(rest, index + 7 + string.length(arg), [
                IfBlockStart(path),
                ..tokens
              ])
          }
        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    "{{/unless" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#("", rest)) -> run(rest, index + 11, [UnlessBlockEnd, ..tokens])
        _ -> Error(error.UnexpectedBlockArgument(index + 2))
      }
    "{{#unless" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(arg, rest)) ->
          case arg |> string.trim |> string.split(".") {
            [""] -> Error(error.MissingBlockArgument(index + 2))
            path ->
              run(rest, index + 11 + string.length(arg), [
                UnlessBlockStart(path),
                ..tokens
              ])
          }
        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    "{{/each" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#("", rest)) -> run(rest, index + 9, [EachBlockEnd, ..tokens])
        _ -> Error(error.UnexpectedBlockArgument(index + 2))
      }
    "{{#each" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(arg, rest)) ->
          case arg |> string.trim |> string.split(".") {
            [""] -> Error(error.MissingBlockArgument(index + 2))
            path ->
              run(rest, index + 9 + string.length(arg), [
                EachBlockStart(path),
                ..tokens
              ])
          }

        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    "{{/" <> _ -> Error(error.UnexpectedBlockKind(index + 2))
    "{{#" <> _ -> Error(error.UnexpectedBlockKind(index + 2))

    "{{" <> rest ->
      case rest |> string.split_once("}}") {
        Ok(#(body, rest)) ->
          case body |> string.trim |> string.split(".") {
            [""] -> Error(error.MissingPropertyPath(index + 2))
            path ->
              run(rest, index + 4 + string.length(body), [
                Property(path),
                ..tokens
              ])
          }
        Error(_) -> Error(error.UnbalancedTag(index + 2))
      }

    _ ->
      case input |> string.split_once("{{") {
        Ok(#(str, rest)) ->
          run("{{" <> rest, index + string.length(str), [
            Constant(str),
            ..tokens
          ])
        _ ->
          case input {
            "" -> Ok(list.reverse(tokens))
            str -> Ok(list.reverse([Constant(str), ..tokens]))
          }
      }
  }
}
