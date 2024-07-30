import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import handles/error
import handles/internal/block

pub type Token {
  Constant(index: Int, value: String)
  Property(index: Int, path: List(String))
  Partial(index: Int, id: String, path: List(String))
  BlockStart(index: Int, kind: block.Kind, path: List(String))
  BlockEnd(index: Int, kind: block.Kind)
}

type Action {
  AddToken(token: Token, new_index: Int, rest_of_input: String)
  Stop(error.TokenizerError)
  Done
}

/// {{
const length_of_open_tag_syntax = 2

/// {{#}} or {{/}} or {{>}}
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
    index + length_of_open_tag_syntax
    |> error.UnbalancedTag
  })
}

fn stop(index: Int, to_error: fn(Int) -> error.TokenizerError) -> Action {
  index + length_of_open_tag_syntax
  |> to_error
  |> Stop
}

fn add_block_sized_token(
  token: Token,
  index: Int,
  consumed: String,
  rest: String,
) -> Action {
  AddToken(
    token,
    index + length_of_block_syntax + string.length(consumed),
    rest,
  )
}

fn tokenize(input: String, index: Int) -> Action {
  case input {
    "" -> Done
    "{{>" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> stop(index, error.MissingPartialId)
            [_] -> stop(index, error.MissingArgument)
            [id, arg] ->
              Partial(index + length_of_open_tag_syntax, id, split_arg(arg))
              |> add_block_sized_token(index, body, rest)
            _ -> stop(index, error.UnexpectedMultipleArguments)
          }
      }

    "{{#" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> stop(index, error.MissingBlockKind)
            [_] -> stop(index, error.MissingArgument)
            ["if", arg] ->
              BlockStart(
                index + length_of_open_tag_syntax,
                block.If,
                split_arg(arg),
              )
              |> add_block_sized_token(index, body, rest)
            ["unless", arg] ->
              BlockStart(
                index + length_of_open_tag_syntax,
                block.Unless,
                split_arg(arg),
              )
              |> add_block_sized_token(index, body, rest)
            ["each", arg] ->
              BlockStart(
                index + length_of_open_tag_syntax,
                block.Each,
                split_arg(arg),
              )
              |> add_block_sized_token(index, body, rest)
            [_, _] -> stop(index, error.UnexpectedBlockKind)
            _ -> stop(index, error.UnexpectedMultipleArguments)
          }
      }

    "{{/" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> stop(index, error.MissingBlockKind)
            [_, _] -> stop(index, error.UnexpectedArgument)
            ["if"] ->
              BlockEnd(index + length_of_open_tag_syntax, block.If)
              |> add_block_sized_token(index, body, rest)
            ["unless"] ->
              BlockEnd(index + length_of_open_tag_syntax, block.Unless)
              |> add_block_sized_token(index, body, rest)
            ["each"] ->
              BlockEnd(index + length_of_open_tag_syntax, block.Each)
              |> add_block_sized_token(index, body, rest)
            [_] -> stop(index, error.UnexpectedBlockKind)
            _ -> stop(index, error.UnexpectedArgument)
          }
      }

    "{{" <> rest ->
      case capture_tag_body(rest, index) {
        Error(err) -> Stop(err)
        Ok(#(body, rest)) ->
          case split_body(body) {
            [] -> stop(index, error.MissingArgument)
            [arg] ->
              AddToken(
                Property(index + length_of_open_tag_syntax, split_arg(arg)),
                index + length_of_property_syntax + string.length(body),
                rest,
              )
            _ -> stop(index, error.UnexpectedMultipleArguments)
          }
      }
    _ ->
      case
        input
        |> string.split_once("{{")
        |> result.map(pair.map_second(_, fn(it) { "{{" <> it }))
      {
        Ok(#(str, rest)) ->
          AddToken(Constant(index, str), index + string.length(str), rest)
        _ -> AddToken(Constant(index, input), index + string.length(input), "")
      }
  }
}

fn do_run(
  input: String,
  index: Int,
  tokens: List(Token),
) -> Result(List(Token), error.TokenizerError) {
  case tokenize(input, index) {
    Done -> Ok(list.reverse(tokens))
    Stop(err) -> Error(err)
    AddToken(token, index, rest) -> do_run(rest, index, [token, ..tokens])
  }
}

pub fn run(input: String) -> Result(List(Token), error.TokenizerError) {
  do_run(input, 0, [])
}
