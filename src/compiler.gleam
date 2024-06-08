import gleam/iterator
import gleam/list
import gleam/result
import gleam/string
import parser

pub type CompileError {
  MissingBlockKind(start: Int, end: Int)
  ToManyBlockArguments(start: Int, end: Int)
  EmptyExpression(start: Int, end: Int)
  UnbalancedBlock(kind: String)
}

pub type AST {
  Constant(value: String)
  Property(path: List(String))
  BlockStart(kind: String, args: List(String))
  BlockEnd(kind: String)
}

pub fn compile(
  tokens: iterator.Iterator(parser.Token),
) -> Result(List(AST), List(CompileError)) {
  let #(out, stack) =
    tokens
    |> iterator.map(fn(token) {
      case token {
        parser.Template(_, _, value) -> Ok(Constant(value))
        parser.Expression(start, end, value) -> {
          let val = string.trim(value)
          case string.first(val) {
            Ok("#") ->
              case string.split(string.drop_left(val, 1), " ") {
                [""] -> Error(MissingBlockKind(start, end))
                [kind] -> Ok(BlockStart(kind, []))
                [kind, ..args] -> Ok(BlockStart(kind, args))
                _ -> panic as "This should never happen"
              }
            Ok("/") ->
              case string.split(string.drop_left(val, 1), " ") {
                [""] -> Error(MissingBlockKind(start, end))
                [kind] -> Ok(BlockEnd(kind))
                [_, _, ..] -> Error(ToManyBlockArguments(start, end))
                [] -> panic as "This should never happen"
              }
            Ok(_) -> Ok(Property(string.split(value, ".")))
            Error(_) -> Error(EmptyExpression(start, end))
          }
        }
      }
    })
    |> iterator.fold(#([], []), fn(acc, it) {
      let #(out, stack) = acc
      case it {
        Ok(BlockStart(kind, _)) -> #([it, ..out], [kind, ..stack])
        Ok(BlockEnd(kind)) ->
          case list.first(stack) {
            Ok(top) if top == kind ->
              case list.rest(stack) {
                Ok(rest) -> #([it, ..out], rest)
                _ -> #([Error(UnbalancedBlock(kind)), ..out], [])
              }
            _ ->
              case list.rest(stack) {
                Ok(rest) -> #([it, ..out], rest)
                _ -> #([Error(UnbalancedBlock(kind)), ..out], [])
              }
          }
        _ -> #([it, ..out], stack)
      }
    })

  case
    list.concat([out, list.map(stack, fn(it) { Error(UnbalancedBlock(it)) })])
    |> result.partition
  {
    #(ok, []) -> Ok(ok)
    #(_, err) -> Error(err)
  }
}
