import gleam/int
import gleam/list
import gleam/string
import handles/lexer

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

pub fn format_parse_error(error: lexer.LexError, template: String) -> String {
  case error {
    lexer.UnbalancedTag(index, _) ->
      case resolve_position(template, index, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Tag is missing closing braces }} ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            ")",
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
    lexer.SyntaxError(errors) ->
      errors
      |> list.fold("", fn(acc, err) {
        string.concat([acc, "\n", format_syntax_error(err, template)])
      })
  }
}

pub fn format_syntax_error(error: lexer.SyntaxError, template: String) -> String {
  case error {
    lexer.MissingBody(start, _) ->
      case resolve_position(template, start, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Tag is missing a body ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            ")",
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
    lexer.MissingBlockKind(start, _) ->
      case resolve_position(template, start, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Tag is of unknown block kind ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            ")",
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
    lexer.UnexpectedBlockArgument(start, _) ->
      case resolve_position(template, start, Position(0, 0, 0)) {
        Position(_, row, col) ->
          string.concat([
            "Tag is a closing block, which does not take any arguments ",
            "(row=",
            int.to_string(row),
            ", col=",
            int.to_string(col),
            ")",
          ])
        OutOfBounds -> panic as "Unable to resolve error position in template"
      }
  }
}
