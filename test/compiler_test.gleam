import compiler
import gleam/iterator
import gleam/option.{None, Some}
import gleeunit/should
import parser

pub fn compiler_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([])
}

pub fn compiler_should_return_correct_when_compiling_hello_world_test() {
  [parser.Template(0, 6, "Hello "), parser.Expression(8, 12, "name")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.Constant("Hello "), compiler.Property(["name"])])
}

pub fn compiler_should_return_correct_when_compiling_one_constant_test() {
  [parser.Template(0, 11, "Hello World")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.Constant("Hello World")])
}

pub fn compiler_should_return_correct_when_compiling_one_property_test() {
  [parser.Expression(0, 7, "foo.bar")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.Property(["foo", "bar"])])
}

pub fn compiler_should_return_correct_when_compiling_one_block_start_with_arg_test() {
  [parser.Expression(0, 7, "#foo bar.biz")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.BlockStart("foo", Some(["bar", "biz"]))])
}

pub fn compiler_should_return_correct_when_compiling_one_block_start_without_arg_test() {
  [parser.Expression(0, 7, "#foo")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.BlockStart("foo", None)])
}

pub fn compiler_should_return_correct_when_compiling_one_block_end_test() {
  [parser.Expression(0, 7, "/foo")]
  |> iterator.from_list
  |> compiler.compile
  |> iterator.to_list
  |> should.equal([compiler.BlockEnd("foo")])
}
