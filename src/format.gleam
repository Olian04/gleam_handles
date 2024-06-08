import gleam/int
import gleam/string
import parser

type Position {
  Position(index: Int, row: Int, col: Int)
  OutOfBounds
}

fn resolve_position(
  input: String,
  target_index: Int,
  current: Position,
) -> Position {
  case current {
    Position(index, row, col) if index == target_index ->
      Position(target_index, row, col)
    Position(index, row, col) ->
      case string.first(input) {
        Ok(char) ->
          case char {
            "\n" ->
              resolve_position(
                string.drop_left(input, 1),
                target_index,
                Position(index + 1, row + 1, 0),
              )
            _ ->
              resolve_position(
                string.drop_left(input, 1),
                target_index,
                Position(index + 1, row, col + 1),
              )
          }
        Error(_) -> OutOfBounds
      }
    OutOfBounds -> OutOfBounds
  }
}

pub fn parse_error(error: parser.ParseError, template: String) -> String {
  case error {
    parser.UnexpectedEof(index) ->
      case resolve_position(template, index, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Unexpected end of template ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            ")",
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
    parser.UnexpectedToken(index, char) ->
      case resolve_position(template, index, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Unexpected token ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            "): ",
            char,
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
  }
}
