import gleam/iterator
import gleam/option.{type Option, None, Some}
import gleam/string
import parser

pub type CompileError {
  MissingBlockKind(start: Int, end: Int)
  ToManyBlockArguments(start: Int, end: Int)
  EmptyExpression(start: Int, end: Int)
  UnknownError(start: Int, end: Int)
}

pub type AST {
  Constant(value: String)
  Property(path: List(String))
  BlockStart(kind: String, property_path: Option(List(String)))
  BlockEnd(kind: String)
  AstError(CompileError)
}

pub fn compile(
  tokens: iterator.Iterator(parser.Token),
) -> iterator.Iterator(AST) {
  tokens
  |> iterator.map(fn(token) {
    case token {
      parser.Template(_, _, value) -> Constant(value)
      parser.Expression(start, end, value) -> {
        let val = string.trim(value)
        case string.first(val) {
          Ok("#") ->
            case string.split(string.drop_left(val, 1), " ") {
              [kind, prop_path] ->
                BlockStart(kind, Some(string.split(prop_path, ".")))
              [kind] -> BlockStart(kind, None)
              [] -> AstError(MissingBlockKind(start, end))
              _ -> AstError(ToManyBlockArguments(start, end))
            }
          Ok("/") ->
            case string.split(string.drop_left(val, 1), " ") {
              [kind] -> BlockEnd(kind)
              [] -> AstError(MissingBlockKind(start, end))
              _ -> AstError(ToManyBlockArguments(start, end))
            }
          Ok(_) -> Property(string.split(value, "."))
          Error(_) -> AstError(EmptyExpression(start, end))
        }
      }
    }
  })
}
