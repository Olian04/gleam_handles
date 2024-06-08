import gleam/result
import gleam/string

pub type Token {
  Constant(start: Int, end: Int, value: String)
  Property(start: Int, end: Int, path: List(String))
  BlockStart(start: Int, end: Int, kind: String, args: List(String))
  BlockEnd(start: Int, end: Int, kind: String)
}

pub type ParseError {
  UnexpectedToken(index: Int, str: String)
  UnexpectedEof(index: Int)
}

pub type SyntaxError {
  EmptyExpression(start: Int, end: Int)
  MissingBlockKind(start: Int, end: Int)
  UnexpectedBlockArgument(start: Int, end: Int)
}

type ParserState {
  Static(start: Int, end: Int, str: String)
  Tag(start: Int, end: Int, str: String)
  TagStart(start: Int)
  TagEnd(start: Int)
}

fn step(
  acc: List(Result(Token, SyntaxError)),
  state: ParserState,
  input: String,
) -> Result(List(Result(Token, SyntaxError)), ParseError) {
  case state {
    Static(start, end, str) ->
      case string.first(input) {
        Ok("{") ->
          step(
            [Ok(Constant(start, end, str)), ..acc],
            TagStart(end + 1),
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            acc,
            Static(start, end + 1, string.append(str, char)),
            string.drop_left(input, 1),
          )
        Error(_) -> Ok([Ok(Constant(start, end, str)), ..acc])
      }
    Tag(start, end, value) ->
      case string.first(input) {
        Ok("}") ->
          step(
            [
              {
                let val = string.trim(value)
                case string.first(val) {
                  Ok("#") ->
                    case string.split(string.drop_left(val, 1), " ") {
                      [""] -> Error(MissingBlockKind(start, end))
                      [kind] -> Ok(BlockStart(start, end, kind, []))
                      [kind, ..args] -> Ok(BlockStart(start, end, kind, args))
                      _ -> panic as "This should never happen"
                    }
                  Ok("/") ->
                    case string.split(string.drop_left(val, 1), " ") {
                      [""] -> Error(MissingBlockKind(start, end))
                      [kind] -> Ok(BlockEnd(start, end, kind))
                      [_, _, ..] -> Error(UnexpectedBlockArgument(start, end))
                      [] -> panic as "This should never happen"
                    }
                  Ok(_) -> Ok(Property(start, end, string.split(value, ".")))
                  Error(_) -> Error(EmptyExpression(start, end))
                }
              },
              ..acc
            ],
            TagEnd(end + 1),
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            acc,
            Tag(start, end + 1, string.append(value, char)),
            string.drop_left(input, 1),
          )
        Error(_) -> Error(UnexpectedEof(end))
      }
    TagStart(start) ->
      case string.first(input) {
        Ok("{") ->
          step(acc, Tag(start + 1, start + 1, ""), string.drop_left(input, 1))
        Ok(char) -> Error(UnexpectedToken(start, char))
        Error(_) -> Error(UnexpectedEof(start))
      }
    TagEnd(start) ->
      case string.first(input) {
        Ok("}") ->
          step(
            acc,
            Static(start + 1, start + 1, ""),
            string.drop_left(input, 1),
          )
        Ok(char) -> Error(UnexpectedToken(start, char))
        Error(_) -> Error(UnexpectedEof(start))
      }
  }
}

pub fn parse(
  template: String,
) -> Result(Result(List(Token), List(SyntaxError)), ParseError) {
  case step([], Static(0, 0, ""), template) {
    Ok(tokens) ->
      case
        tokens
        |> result.partition
      {
        #(ok, []) -> Ok(Ok(ok))
        #(_, err) -> Ok(Error(err))
      }
    Error(err) -> Error(err)
  }
}
