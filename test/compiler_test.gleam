import compiler
import gleeunit/should
import parser

pub fn compiler_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> compiler.compile([])
  |> should.be_ok
  |> should.equal([])
}
// pub fn compiler_should_return_correct_when_compiling_hello_world_test() {
//   [parser.Template(0, 6, "Hello "), parser.Expression(8, 12, "name")]
//   |> iterator.from_list
//   |> compiler.compile([])
//   |> should.be_ok
//   |> should.equal([
//     compiler.Constant(0, 6, "Hello "),
//     compiler.Property(8, 12, ["name"]),
//   ])
// }

// pub fn compiler_should_return_correct_when_compiling_one_constant_test() {
//   [parser.Template(0, 11, "Hello World")]
//   |> iterator.from_list
//   |> compiler.compile([])
//   |> should.be_ok
//   |> should.equal([compiler.Constant(0, 11, "Hello World")])
// }

// pub fn compiler_should_return_correct_when_compiling_one_property_test() {
//   [parser.Expression(0, 7, "foo.bar")]
//   |> iterator.from_list
//   |> compiler.compile([])
//   |> should.be_ok
//   |> should.equal([compiler.Property(0, 7, ["foo", "bar"])])
// }

// pub fn compiler_should_return_correct_when_compiling_one_block_with_arg_test() {
//   [parser.Expression(0, 7, "#foo bar.biz"), parser.Expression(0, 7, "/foo")]
//   |> iterator.from_list
//   |> compiler.compile(["foo"])
//   |> should.be_ok
//   |> should.equal([
//     compiler.BlockStart(0, 7, "foo", ["bar.biz"]),
//     compiler.BlockEnd(0, 7, "foo"),
//   ])
// }

// pub fn compiler_should_return_correct_when_compiling_one_without_arg_test() {
//   [parser.Expression(0, 7, "#foo"), parser.Expression(0, 7, "/foo")]
//   |> iterator.from_list
//   |> compiler.compile(["foo"])
//   |> should.be_ok
//   |> should.equal([
//     compiler.BlockStart(0, 7, "foo", []),
//     compiler.BlockEnd(0, 7, "foo"),
//   ])
// }

// pub fn compiler_should_return_error_when_missing_block_kind_test() {
//   [parser.Expression(0, 1, "#")]
//   |> iterator.from_list
//   |> compiler.compile([])
//   |> should.be_error
//   |> should.equal([compiler.MissingBlockKind(0, 1)])
// }

// pub fn compiler_should_return_error_when_providing_arguments_to_end_block_test() {
//   [parser.Expression(0, 8, "/foo bar")]
//   |> iterator.from_list
//   |> compiler.compile(["foo"])
//   |> should.be_error
//   |> should.equal([compiler.ToManyBlockArguments(0, 8)])
// }

// pub fn compiler_should_return_error_when_providing_no_end_block_test() {
//   [parser.Expression(0, 8, "#foo")]
//   |> iterator.from_list
//   |> compiler.compile(["foo"])
//   |> should.be_error
//   |> should.equal([compiler.UnbalancedBlock(-1, -1, "foo")])
// }

// pub fn compiler_should_return_error_when_providing_unknown_block_kind_test() {
//   [parser.Expression(0, 0, "#foo")]
//   |> iterator.from_list
//   |> compiler.compile([])
//   |> should.be_error
//   |> should.equal([compiler.UnknownBlockKind(0, 0, "foo")])
// }

// pub fn compiler_should_return_error_when_providing_empty_expression_test() {
//   [parser.Expression(0, 0, "")]
//   |> iterator.from_list
//   |> compiler.compile(["foo"])
//   |> should.be_error
//   |> should.equal([compiler.EmptyExpression(0, 0)])
// }
