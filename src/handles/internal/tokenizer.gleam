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

/// {{
const length_of_open_tag_syntax = 2

/// {{#}} or {{#/}} or {{>}}
const length_of_block_syntax = 5

/// {{}}
const length_of_property_syntax = 4

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
  |> result.map_error(fn(_) {
    error.UnbalancedTag(index + length_of_open_tag_syntax)
  })
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
        [] -> Error(error.MissingPartialId(index + length_of_open_tag_syntax))
        [_] -> Error(error.MissingArgument(index + length_of_open_tag_syntax))
        [id, arg] ->
          run(rest, index + string.length("{{>}}") + string.length(body), [
            Partial(index + length_of_open_tag_syntax, id, split_arg(arg)),
            ..tokens
          ])
        _ ->
          Error(error.UnexpectedMultipleArguments(
            index + length_of_open_tag_syntax,
          ))
      }
    }

    "{{#" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingBlockKind(index + length_of_open_tag_syntax))
        [_] -> Error(error.MissingArgument(index + length_of_open_tag_syntax))
        [kind, arg] ->
          case kind {
            "if" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                IfBlockStart(index + length_of_open_tag_syntax, split_arg(arg)),
                ..tokens
              ])
            "unless" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                UnlessBlockStart(
                  index + length_of_open_tag_syntax,
                  split_arg(arg),
                ),
                ..tokens
              ])
            "each" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                EachBlockStart(
                  index + length_of_open_tag_syntax,
                  split_arg(arg),
                ),
                ..tokens
              ])
            _ -> Error(error.UnexpectedBlockKind(index))
          }
        _ ->
          Error(error.UnexpectedMultipleArguments(
            index + length_of_open_tag_syntax,
          ))
      }
    }

    "{{/" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingBlockKind(index + length_of_open_tag_syntax))
        [_, _] ->
          Error(error.UnexpectedArgument(index + length_of_open_tag_syntax))
        [kind] ->
          case kind {
            "if" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                IfBlockEnd(index + length_of_open_tag_syntax),
                ..tokens
              ])
            "unless" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                UnlessBlockEnd(index + length_of_open_tag_syntax),
                ..tokens
              ])
            "each" ->
              run(rest, index + length_of_block_syntax + string.length(body), [
                EachBlockEnd(index + length_of_open_tag_syntax),
                ..tokens
              ])
            _ -> Error(error.UnexpectedBlockKind(index))
          }
        _ -> Error(error.UnexpectedArgument(index + length_of_open_tag_syntax))
      }
    }

    "{{" <> rest -> {
      use #(body, rest) <- result.try(capture_tag_body(rest, index))
      case split_body(body) {
        [] -> Error(error.MissingArgument(index + length_of_open_tag_syntax))
        [arg] ->
          run(rest, index + length_of_property_syntax + string.length(body), [
            Property(index + length_of_open_tag_syntax, split_arg(arg)),
            ..tokens
          ])
        _ ->
          Error(error.UnexpectedMultipleArguments(
            index + length_of_open_tag_syntax,
          ))
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
