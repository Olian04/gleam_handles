import gleam/list
import handles/internal/tokenizer

pub type AST {
  Constant(index: Int, value: String)
  Property(index: Int, path: List(String))
  Partial(index: Int, id: String, path: List(String))
  IfBlock(index: Int, path: List(String), children: List(AST))
  UnlessBlock(index: Int, path: List(String), children: List(AST))
  EachBlock(index: Int, path: List(String), children: List(AST))
}

pub fn run(tokens: List(tokenizer.Token), ast: List(AST)) -> List(AST) {
  case tokens {
    [] -> list.reverse(ast)
    [head, ..tail] -> {
      case head {
        tokenizer.Constant(index, value) ->
          run(tail, [Constant(index, value), ..ast])
        tokenizer.Property(index, path) ->
          run(tail, [Property(index, path), ..ast])
        tokenizer.Partial(index, id, value) ->
          run(tail, [Partial(index, id, value), ..ast])
        tokenizer.IfBlockStart(index, path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            IfBlock(index, path, children),
            ..ast
          ])
        }
        tokenizer.UnlessBlockStart(index, path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            UnlessBlock(index, path, children),
            ..ast
          ])
        }
        tokenizer.EachBlockStart(index, path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            EachBlock(index, path, children),
            ..ast
          ])
        }
        tokenizer.IfBlockEnd(_) -> list.reverse(ast)
        tokenizer.UnlessBlockEnd(_) -> list.reverse(ast)
        tokenizer.EachBlockEnd(_) -> list.reverse(ast)
      }
    }
  }
}
