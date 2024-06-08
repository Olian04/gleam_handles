import compiler
import gleam/iterator
import gleeunit/should
import parser

pub fn compiler_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([])
}

pub fn compiler_should_return_correct_when_compiling_one_constant_test() {
  [parser.Template(0, 11, "Hello World")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.Constant("Hello World")])
}
