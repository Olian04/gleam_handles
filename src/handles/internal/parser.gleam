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
  BlockEnd(
    index: Int,
    kind: block.Kind,
    children: List(AST),
    rest: List(tokenizer.Token),
  )
}

fn parse(
  ast: List(AST),
  tokens: List(tokenizer.Token),
) -> Result(ParseResult, error.TokenizerError) {
  case tokens {
    [] -> Ok(EOF(list.reverse(ast)))
    [tokenizer.BlockEnd(index, kind), ..tail] ->
      Ok(BlockEnd(index, kind, list.reverse(ast), tail))

    [tokenizer.Constant(index, value), ..tail] ->
      [Constant(index, value), ..ast]
      |> parse(tail)
    [tokenizer.Property(index, path), ..tail] ->
      [Property(index, path), ..ast]
      |> parse(tail)
    [tokenizer.Partial(index, id, value), ..tail] ->
      [Partial(index, id, value), ..ast]
      |> parse(tail)

    [tokenizer.BlockStart(start_index, start_kind, path), ..tail] ->
      case parse([], tail) {
        Error(err) -> Error(err)
        Ok(EOF(_)) ->
          start_index
          |> error.UnbalancedBlock
          |> Error
        Ok(BlockEnd(end_index, end_kind, children, rest))
          if end_kind == start_kind
        ->
          [Block(start_index, end_index, start_kind, path, children), ..ast]
          |> parse(rest)
        Ok(BlockEnd(index, _, _, _)) ->
          index
          |> error.UnexpectedBlockEnd
          |> Error
      }
  }
}

pub fn run(
  tokens: List(tokenizer.Token),
) -> Result(List(AST), error.TokenizerError) {
  parse([], tokens)
  |> result.try(fn(it) {
    case it {
      EOF(ast) -> Ok(ast)
      BlockEnd(index, _, _, _) ->
        index
        |> error.UnexpectedBlockEnd
        |> Error
    }
  })
}
