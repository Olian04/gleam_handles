import gleam/list
import handles/internal/tokenizer

pub type AST {
  Constant(value: String)
  Property(path: List(String))
  IfBlock(path: List(String), children: List(AST))
  UnlessBlock(path: List(String), children: List(AST))
  EachBlock(path: List(String), children: List(AST))
}

pub fn run(tokens: List(tokenizer.Token), ast: List(AST)) -> List(AST) {
  case tokens {
    [] -> list.reverse(ast)
    [head, ..tail] -> {
      case head {
        tokenizer.Constant(value) -> run(tail, [Constant(value), ..ast])
        tokenizer.Property(path) -> run(tail, [Property(path), ..ast])
        tokenizer.IfBlockStart(path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            IfBlock(path, children),
            ..ast
          ])
        }
        tokenizer.UnlessBlockStart(path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            UnlessBlock(path, children),
            ..ast
          ])
        }
        tokenizer.EachBlockStart(path) -> {
          let children = run(tail, [])
          run(list.drop(tail, list.length(children) + 1), [
            EachBlock(path, children),
            ..ast
          ])
        }
        tokenizer.IfBlockEnd -> list.reverse(ast)
        tokenizer.UnlessBlockEnd -> list.reverse(ast)
        tokenizer.EachBlockEnd -> list.reverse(ast)
      }
    }
  }
}
