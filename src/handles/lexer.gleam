import gleam/result
import gleam/string

pub type Token {
  Constant(start: Int, end: Int, value: String)
  Property(start: Int, end: Int, path: List(String))
  BlockStart(start: Int, end: Int, kind: String, path: List(String))
  BlockEnd(start: Int, end: Int, kind: String)
}

pub type LexError {
  UnbalancedTag(start: Int, end: Int)
  SyntaxError(errors: List(SyntaxError))
}

pub type SyntaxError {
  MissingBody(start: Int, end: Int)
  MissingBlockKind(start: Int, end: Int)
  UnexpectedBlockArgument(start: Int, end: Int)
}

type LexerState {
  Static(start: Int, end: Int, str: String)
  Tag(start: Int, end: Int, str: String)
}

fn to_block_or_property(start: Int, end: Int, value: String) {
  let val = string.trim(value)
  case string.first(val) {
    Ok("#") ->
      case string.split_once(string.drop_left(val, 1), " ") {
        Ok(#(kind, body)) ->
          Ok(BlockStart(start, end, kind, string.split(body, ".")))
        Error(_) -> Error(MissingBlockKind(start, end))
      }
    Ok("/") ->
      case string.split_once(string.drop_left(val, 1), " ") {
        Ok(#(_, _)) -> Error(UnexpectedBlockArgument(start, end))
        Error(_) -> Ok(BlockEnd(start, end, string.drop_left(val, 1)))
      }
    Ok(_) -> Ok(Property(start, end, string.split(value, ".")))
    Error(_) -> Error(MissingBody(start, end))
  }
}

fn step(
  state: LexerState,
  acc: List(Result(Token, SyntaxError)),
  input: String,
) -> Result(List(Result(Token, SyntaxError)), LexError) {
  case state {
    Static(start, end, str) ->
      case string.starts_with(input, "{{") {
        True ->
          step(
            Tag(end + 2, end + 2, ""),
            [Ok(Constant(start, end, str)), ..acc],
            string.drop_left(input, 2),
          )
        False ->
          case string.first(input) {
            Ok(char) ->
              step(
                Static(start, end + 1, string.append(str, char)),
                acc,
                string.drop_left(input, 1),
              )
            Error(_) -> Ok([Ok(Constant(start, end, str)), ..acc])
          }
      }
    Tag(start, end, value) ->
      case string.starts_with(input, "}}") {
        True ->
          step(
            Static(end + 2, end + 2, ""),
            [to_block_or_property(start, end, value), ..acc],
            string.drop_left(input, 2),
          )
        False ->
          case string.first(input) {
            Ok(char) ->
              step(
                Tag(start, end + 1, string.append(value, char)),
                acc,
                string.drop_left(input, 1),
              )
            Error(_) -> Error(UnbalancedTag(start, end))
          }
      }
  }
}

pub fn run(template: String) -> Result(List(Token), LexError) {
  case step(Static(0, 0, ""), [], template) {
    Ok(tokens) ->
      case
        tokens
        |> result.partition
      {
        #(ok, []) -> Ok(ok)
        #(_, err) -> Error(SyntaxError(err))
      }
    Error(err) -> Error(err)
  }
}
