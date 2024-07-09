import gleam/list
import gleam/pair
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

type Action {
  AddToken(String, Int, Token)
  Stop(error.TokenizerError)
  Done
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

fn tokenize(input: String, index: Int) -> Action {
  case input {
    "" -> Done
    "{{>" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] ->
              Stop(error.MissingPartialId(index + length_of_open_tag_syntax))
            [_] ->
              Stop(error.MissingArgument(index + length_of_open_tag_syntax))
            [id, arg] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                Partial(index + length_of_open_tag_syntax, id, split_arg(arg)),
              )
            _ ->
              Stop(error.UnexpectedMultipleArguments(
                index + length_of_open_tag_syntax,
              ))
          }
      }

    "{{#" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] ->
              Stop(error.MissingBlockKind(index + length_of_open_tag_syntax))
            [_] ->
              Stop(error.MissingArgument(index + length_of_open_tag_syntax))
            ["if", arg] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                IfBlockStart(index + length_of_open_tag_syntax, split_arg(arg)),
              )
            ["unless", arg] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                UnlessBlockStart(
                  index + length_of_open_tag_syntax,
                  split_arg(arg),
                ),
              )
            ["each", arg] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                EachBlockStart(
                  index + length_of_open_tag_syntax,
                  split_arg(arg),
                ),
              )
            [_, _] ->
              Stop(error.UnexpectedBlockKind(index + length_of_open_tag_syntax))
            _ ->
              Stop(error.UnexpectedMultipleArguments(
                index + length_of_open_tag_syntax,
              ))
          }
      }

    "{{/" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] ->
              Stop(error.MissingBlockKind(index + length_of_open_tag_syntax))
            [_, _] ->
              Stop(error.UnexpectedArgument(index + length_of_open_tag_syntax))
            ["if"] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                IfBlockEnd(index + length_of_open_tag_syntax),
              )
            ["unless"] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                UnlessBlockEnd(index + length_of_open_tag_syntax),
              )
            ["each"] ->
              AddToken(
                rest,
                index + length_of_block_syntax + string.length(body),
                EachBlockEnd(index + length_of_open_tag_syntax),
              )
            [_] ->
              Stop(error.UnexpectedBlockKind(index + length_of_open_tag_syntax))
            _ ->
              Stop(error.UnexpectedArgument(index + length_of_open_tag_syntax))
          }
      }

    "{{" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> Stop(error.MissingArgument(index + length_of_open_tag_syntax))
            [arg] ->
              AddToken(
                rest,
                index + length_of_property_syntax + string.length(body),
                Property(index + length_of_open_tag_syntax, split_arg(arg)),
              )
            _ ->
              Stop(error.UnexpectedMultipleArguments(
                index + length_of_open_tag_syntax,
              ))
          }
      }
    _ ->
      case
        input
        |> string.split_once("{{")
        |> result.map(pair.map_second(_, fn(it) { "{{" <> it }))
      {
        Ok(#(str, rest)) ->
          AddToken(rest, index + string.length(str), Constant(index, str))
        _ -> AddToken("", index + string.length(input), Constant(index, input))
      }
  }
}

pub fn run(
  input: String,
  index: Int,
  tokens: List(Token),
) -> Result(List(Token), error.TokenizerError) {
  case tokenize(input, index) {
    Done -> Ok(list.reverse(tokens))
    Stop(err) -> Error(err)
    AddToken(rest, index, token) -> run(rest, index, [token, ..tokens])
  }
}
