import gleam/iterator
import gleam/string

pub type Token {
  Template(Int, Int, String)
  Expression(Int, Int, String)
}

type ParserState {
  Static(Int, Int, String)
  Tag(Int, Int, String)
  TagStart(Int)
  TagEnd(Int)
}

fn step(
  iter: iterator.Iterator(Token),
  state: ParserState,
  input: String,
) -> Result(iterator.Iterator(Token), String) {
  case state {
    Static(start, end, str) ->
      case string.first(input) {
        Ok("{") ->
          step(
            iterator.append(
              iter,
              iterator.once(fn() { Template(start, end, str) }),
            ),
            TagStart(end + 1),
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            iter,
            Static(start, end + 1, string.append(str, char)),
            string.drop_left(input, 1),
          )
        Error(_) ->
          Ok(iterator.append(
            iter,
            iterator.once(fn() { Template(start, end, str) }),
          ))
      }
    Tag(start, end, str) ->
      case string.first(input) {
        Ok("}") ->
          step(
            iterator.append(
              iter,
              iterator.once(fn() { Expression(start, end, str) }),
            ),
            TagEnd(end + 1),
            string.drop_left(input, 1),
          )
        Ok(char) ->
          step(
            iter,
            Tag(start, end + 1, string.append(str, char)),
            string.drop_left(input, 1),
          )
        Error(_) -> Error("Unexpected EOF")
      }
    TagStart(start) ->
      case string.first(input) {
        Ok("{") ->
          step(iter, Tag(start + 1, start + 1, ""), string.drop_left(input, 1))
        Ok(char) -> Error(string.append("Unexpected token ", char))
        Error(_) -> Error("Unexpected EOF")
      }
    TagEnd(start) ->
      case string.first(input) {
        Ok("}") ->
          step(
            iter,
            Static(start + 1, start + 1, ""),
            string.drop_left(input, 1),
          )
        Ok(char) -> Error(string.append("Unexpected token ", char))
        Error(_) -> Error("Unexpected EOF")
      }
  }
}

pub fn parse(str: String) -> Result(iterator.Iterator(Token), String) {
  step(iterator.empty(), Static(0, 0, ""), str)
}
