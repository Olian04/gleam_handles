import gleam/list
import gleam/result
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

fn split_arg(arg: String) -> List(String) {
  case arg |> string.trim {
    "." -> []
    arg -> string.split(arg, ".")
  }
}

fn capture_tag_body(
  input: String,
  index: Int,
) -> Result(#(String, String), error.TokenizerError) {
  input
  |> string.split_once("}}")
  |> result.map_error(fn(_) { error.UnbalancedTag(index + 2) })
}

pub fn run(
  input: String,
  index: Int,
  tokens: List(Token),
) -> Result(List(Token), error.TokenizerError) {
  case input {
    "{{>" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingPartialId(index + 2))
        [_] -> Error(error.MissingArgument(index + 2))
        [id, arg] ->
          run(rest, index + string.length("{{>}}") + string.length(body), [
            Partial(index + 2, id, split_arg(arg)),
            ..tokens
          ])
        _ -> Error(error.UnexpectedMultipleArguments(index + 2))
      }
    }

    "{{#" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingBlockKind(index + 2))
        [_] -> Error(error.MissingArgument(index + 2))
        [kind, arg] ->
          case kind {
            "if" ->
              run(rest, index + string.length("{{#}}") + string.length(body), [
                IfBlockStart(index + 2, split_arg(arg)),
                ..tokens
              ])
            "unless" ->
              run(rest, index + string.length("{{#}}") + string.length(body), [
                UnlessBlockStart(index + 2, split_arg(arg)),
                ..tokens
              ])
            "each" ->
              run(rest, index + string.length("{{#}}") + string.length(body), [
                EachBlockStart(index + 2, split_arg(arg)),
                ..tokens
              ])
            _ -> Error(error.UnexpectedBlockKind(index))
          }
        _ -> Error(error.UnexpectedMultipleArguments(index + 2))
      }
    }

    "{{/" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingBlockKind(index + 2))
        [_, _] -> Error(error.UnexpectedArgument(index + 2))
        [kind] ->
          case kind {
            "if" ->
              run(rest, index + string.length("{{/}}") + string.length(body), [
                IfBlockEnd(index + 2),
                ..tokens
              ])
            "unless" ->
              run(rest, index + string.length("{{/}}") + string.length(body), [
                UnlessBlockEnd(index + 2),
                ..tokens
              ])
            "each" ->
              run(rest, index + string.length("{{/}}") + string.length(body), [
                EachBlockEnd(index + 2),
                ..tokens
              ])
            _ -> Error(error.UnexpectedBlockKind(index))
          }
        _ -> Error(error.UnexpectedArgument(index + 2))
      }
    }

    "{{" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingArgument(index + 2))
        [arg] ->
          run(rest, index + string.length("{{}}") + string.length(body), [
            Property(index + 2, split_arg(arg)),
            ..tokens
          ])
        _ -> Error(error.UnexpectedMultipleArguments(index + 2))
      }
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
