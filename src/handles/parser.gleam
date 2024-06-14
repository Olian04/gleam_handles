import gleam/list
import gleam/result
import handles/lexer

pub type ParseError {
  UnbalancedBlock(start: Int, end: Int, kind: String)
  UnknownBlockKind(start: Int, end: Int, kind: String)
}

pub type AST {
  Constant(value: String)
  Property(path: List(String))
  Block(kind: String, path: List(String), children: List(AST))
}

fn validation_pass(
  tokens: List(lexer.Token),
  valid_blocks: List(String),
) -> List(Result(lexer.Token, ParseError)) {
  tokens
  |> list.map(fn(it) {
    case it {
      lexer.BlockStart(start, end, kind, _) ->
        case list.contains(valid_blocks, kind) {
          True -> Ok(it)
          False -> Error(UnknownBlockKind(start, end, kind))
        }
      _ -> Ok(it)
    }
  })
}

fn balance_pass(
  tokens: List(Result(lexer.Token, ParseError)),
) -> List(Result(lexer.Token, ParseError)) {
  let #(out, stack) =
    tokens
    |> list.fold(#([], []), fn(acc, it) {
      let #(out, stack) = acc
      case it {
        Ok(lexer.BlockStart(_, _, kind, _)) -> #([it, ..out], [kind, ..stack])
        Ok(lexer.BlockEnd(start, end, kind)) ->
          case list.first(stack) {
            Ok(top) if top == kind ->
              case list.rest(stack) {
                Ok(rest) -> #([it, ..out], rest)
                _ -> #([Error(UnbalancedBlock(start, end, kind)), ..out], [])
              }
            _ ->
              case list.rest(stack) {
                Ok(rest) -> #([it, ..out], rest)
                _ -> #([Error(UnbalancedBlock(start, end, kind)), ..out], [])
              }
          }
        _ -> #([it, ..out], stack)
      }
    })

  list.concat([
    out,
    list.map(stack, fn(it) { Error(UnbalancedBlock(-1, -1, it)) }),
  ])
}

fn ast_transform_pass(
  tokens: List(lexer.Token),
  index: Int,
  ast: List(AST),
) -> List(AST) {
  case tokens {
    [] -> list.reverse(ast)
    [head, ..tail] -> {
      case head {
        lexer.Constant(_, _, value) ->
          ast_transform_pass(tail, index + 1, [Constant(value), ..ast])
        lexer.Property(_, _, path) ->
          ast_transform_pass(tail, index + 1, [Property(path), ..ast])
        lexer.BlockStart(_, _, kind, path) -> {
          let children = ast_transform_pass(tail, index + 1, [])
          ast_transform_pass(
            list.drop(tail, list.length(children)),
            index + 1 + list.length(children),
            [Block(kind, path, children), ..ast],
          )
        }
        lexer.BlockEnd(_, _, _) -> list.reverse(ast)
      }
    }
  }
}

pub fn run(
  tokens: List(lexer.Token),
  valid_blocks: List(String),
) -> Result(List(AST), List(ParseError)) {
  case
    tokens
    |> validation_pass(valid_blocks)
    |> balance_pass
    |> result.partition
  {
    #([lexer.Constant(_, _, ""), ..tokens], []) ->
      // Remove the leading empty string present when the template starts with a tag
      Ok(tokens |> ast_transform_pass(0, []))
    #(tokens, []) -> Ok(tokens |> ast_transform_pass(0, []))
    #(_, err) -> Error(err)
  }
}
