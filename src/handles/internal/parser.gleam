import gleam/list
import gleam/result
import handles/error
import handles/internal/block
import handles/internal/tokenizer

pub type AST {
  Constant(index: Int, value: String)
  Property(index: Int, path: List(String))
  Partial(index: Int, id: String, path: List(String))
  Block(
    start_index: Int,
    end_index: Int,
    kind: block.Kind,
    path: List(String),
    children: List(AST),
  )
}

type ParseResult {
  EOF(List(AST))
  BlockEnd(index: Int, block.Kind, List(AST), List(tokenizer.Token))
}

fn parse(
  tokens: List(tokenizer.Token),
  ast: List(AST),
) -> Result(ParseResult, error.TokenizerError) {
  case tokens {
    [] -> Ok(EOF(list.reverse(ast)))
    [tokenizer.BlockEnd(index, kind), ..tail] ->
      Ok(BlockEnd(index, kind, list.reverse(ast), tail))

    [tokenizer.Constant(index, value), ..tail] ->
      parse(tail, [Constant(index, value), ..ast])
    [tokenizer.Property(index, path), ..tail] ->
      parse(tail, [Property(index, path), ..ast])
    [tokenizer.Partial(index, id, value), ..tail] ->
      parse(tail, [Partial(index, id, value), ..ast])

    [tokenizer.BlockStart(start_index, start_kind, path), ..tail] ->
      case parse(tail, []) {
        Error(err) -> Error(err)
        Ok(EOF(_)) -> Error(error.UnbalancedBlock(start_index))
        Ok(BlockEnd(end_index, end_kind, children, rest))
          if end_kind == start_kind
        ->
          parse(rest, [
            Block(start_index, end_index, start_kind, path, children),
            ..ast
          ])
        Ok(BlockEnd(index, _, _, _)) -> Error(error.UnexpectedBlockEnd(index))
      }
  }
}

pub fn run(
  tokens: List(tokenizer.Token),
) -> Result(List(AST), error.TokenizerError) {
  parse(tokens, [])
  |> result.try(fn(it) {
    case it {
      EOF(ast) -> Ok(ast)
      BlockEnd(index, _, _, _) -> Error(error.UnexpectedBlockEnd(index))
    }
  })
}
