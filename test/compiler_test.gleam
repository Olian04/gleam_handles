import compiler
import gleeunit/should
import parser

pub fn compiler_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> compiler.compile([])
  |> should.be_ok
  |> should.equal([])
}

pub fn compiler_should_return_correct_when_compiling_hello_world_test() {
  [
    parser.Constant(0, 6, "Hello "),
    parser.Property(8, 12, ["name"]),
    parser.Constant(14, 15, "!"),
  ]
  |> compiler.compile([])
  |> should.be_ok
  |> should.equal([
    compiler.Constant("Hello "),
    compiler.Property(["name"]),
    compiler.Constant("!"),
  ])
}

pub fn compiler_should_return_correct_when_compiling_one_constant_test() {
  [parser.Constant(0, 11, "Hello World")]
  |> compiler.compile([])
  |> should.be_ok
  |> should.equal([compiler.Constant("Hello World")])
}

pub fn compiler_should_return_correct_when_compiling_one_property_test() {
  [parser.Property(0, 7, ["foo", "bar"])]
  |> compiler.compile([])
  |> should.be_ok
  |> should.equal([compiler.Property(["foo", "bar"])])
}

pub fn compiler_should_return_correct_when_compiling_one_block_with_arg_test() {
  [parser.BlockStart(0, 7, "foo", ["bar", "biz"]), parser.BlockEnd(0, 7, "foo")]
  |> compiler.compile(["foo"])
  |> should.be_ok
  |> should.equal([compiler.Block("foo", ["bar", "biz"], [])])
}

pub fn compiler_should_return_correct_when_compiling_one_without_arg_test() {
  [parser.BlockStart(0, 7, "foo", []), parser.BlockEnd(0, 7, "foo")]
  |> compiler.compile(["foo"])
  |> should.be_ok
  |> should.equal([compiler.Block("foo", [], [])])
}

pub fn compiler_should_return_error_when_providing_no_end_block_test() {
  [parser.BlockStart(0, 8, "foo", [])]
  |> compiler.compile(["foo"])
  |> should.be_error
  |> should.equal([compiler.UnbalancedBlock(-1, -1, "foo")])
}

pub fn compiler_should_return_error_when_providing_unknown_block_kind_test() {
  [parser.BlockStart(0, 8, "foo", [])]
  |> compiler.compile([])
  |> should.be_error
  |> should.equal([compiler.UnknownBlockKind(0, 8, "foo")])
}
