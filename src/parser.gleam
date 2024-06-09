import gleam/result
import gleam/string

pub type Token {
  Constant(start: Int, end: Int, value: String)
  Expression(start: Int, end: Int, expression: String)
  BlockStart(start: Int, end: Int, kind: String, expression: String)
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
  state: ParserState,
  acc: List(Result(Token, SyntaxError)),
  input: String,
) -> Result(List(Result(Token, SyntaxError)), ParseError) {
  case state {
    Static(start, end, str) ->
      case string.first(input) {
        Ok("{") ->
          step(
            TagStart(end + 1),
            [Ok(Constant(start, end, str)), ..acc],
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            Static(start, end + 1, string.append(str, char)),
            acc,
            string.drop_left(input, 1),
          )
        Error(_) -> Ok([Ok(Constant(start, end, str)), ..acc])
      }
    Tag(start, end, value) ->
      case string.first(input) {
        Ok("}") ->
          step(
            TagEnd(end + 1),
            [
              {
                let val = string.trim(value)
                case string.first(val) {
                  Ok("#") ->
                    case string.split_once(string.drop_left(val, 1), " ") {
                      Ok(#(kind, body)) ->
                        Ok(BlockStart(start, end, kind, body))
                      Error(_) -> Error(MissingBlockKind(start, end))
                    }
                  Ok("/") ->
                    case string.split_once(string.drop_left(val, 1), " ") {
                      Ok(#(_, _)) -> Error(UnexpectedBlockArgument(start, end))
                      Error(_) ->
                        Ok(BlockEnd(start, end, string.drop_left(val, 1)))
                    }
                  Ok(_) -> Ok(Expression(start, end, value))
                  Error(_) -> Error(EmptyExpression(start, end))
                }
              },
              ..acc
            ],
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            Tag(start, end + 1, string.append(value, char)),
            acc,
            string.drop_left(input, 1),
          )
        Error(_) -> Error(UnexpectedEof(end))
      }
    TagStart(start) ->
      case string.first(input) {
        Ok("{") ->
          step(Tag(start + 1, start + 1, ""), acc, string.drop_left(input, 1))
        Ok(char) -> Error(UnexpectedToken(start, char))
        Error(_) -> Error(UnexpectedEof(start))
      }
    TagEnd(start) ->
      case string.first(input) {
        Ok("}") ->
          step(
            Static(start + 1, start + 1, ""),
            acc,
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
  case step(Static(0, 0, ""), [], template) {
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
