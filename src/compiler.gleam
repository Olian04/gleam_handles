import gleam/list
import gleam/result
import parser

pub type CompileError {
  UnbalancedBlock(start: Int, end: Int, kind: String)
  UnknownBlockKind(start: Int, end: Int, kind: String)
}

pub type AST {
  Constant(value: String)
  Property(path: List(String))
  Block(kind: String, args: List(String), children: List(AST))
}

fn validation_pass(
  tokens: List(parser.Token),
  valid_blocks: List(String),
) -> List(Result(parser.Token, CompileError)) {
  tokens
  |> list.map(fn(it) {
    case it {
      parser.BlockStart(start, end, kind, _) ->
        case list.contains(valid_blocks, kind) {
          True -> Ok(it)
          False -> Error(UnknownBlockKind(start, end, kind))
        }
      _ -> Ok(it)
    }
  })
}

fn balance_pass(
  tokens: List(Result(parser.Token, CompileError)),
) -> List(Result(parser.Token, CompileError)) {
  let #(out, stack) =
    tokens
    |> list.fold(#([], []), fn(acc, it) {
      let #(out, stack) = acc
      case it {
        Ok(parser.BlockStart(_, _, kind, _)) -> #([it, ..out], [kind, ..stack])
        Ok(parser.BlockEnd(start, end, kind)) ->
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

fn ast_transform_pass(tokens: List(parser.Token)) -> List(AST) {
  let #(_, out) =
    tokens
    |> list.fold_until(#(0, []), fn(acc, it) {
      case it {
        parser.Constant(_, _, value) ->
          list.Continue(#(acc.0 + 1, list.append(acc.1, [Constant(value)])))
        parser.Property(_, _, path) ->
          list.Continue(#(acc.0 + 1, list.append(acc.1, [Property(path)])))
        parser.BlockStart(_, _, kind, args) ->
          list.Continue(#(
            acc.0 + 1,
            list.append(acc.1, [
              Block(
                kind,
                args,
                ast_transform_pass(list.split(tokens, acc.0 + 1).1),
              ),
            ]),
          ))
        parser.BlockEnd(_, _, _) -> list.Stop(acc)
      }
    })
  out
}

pub fn compile(
  tokens: List(parser.Token),
  valid_blocks: List(String),
) -> Result(List(AST), List(CompileError)) {
  case
    tokens
    |> validation_pass(valid_blocks)
    |> balance_pass
    |> result.partition
  {
    #(ok, []) -> Ok(ok |> ast_transform_pass)
    #(_, err) -> Error(err)
  }
}
