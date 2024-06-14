import gleeunit/should
import handles/lexer
import handles/parser

pub fn parser_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> parser.run([])
  |> should.be_ok
  |> should.equal([])
}

pub fn parser_should_return_correct_when_compiling_hello_world_test() {
  [
    lexer.Constant(0, 6, "Hello "),
    lexer.Property(8, 12, ["name"]),
    lexer.Constant(14, 15, "!"),
  ]
  |> parser.run([])
  |> should.be_ok
  |> should.equal([
    parser.Constant("Hello "),
    parser.Property(["name"]),
    parser.Constant("!"),
  ])
}

pub fn parser_should_return_correct_when_compiling_one_constant_test() {
  [lexer.Constant(0, 11, "Hello World")]
  |> parser.run([])
  |> should.be_ok
  |> should.equal([parser.Constant("Hello World")])
}

pub fn parser_should_return_correct_when_compiling_one_property_test() {
  [lexer.Property(0, 7, ["foo", "bar"])]
  |> parser.run([])
  |> should.be_ok
  |> should.equal([parser.Property(["foo", "bar"])])
}

pub fn parser_should_return_correct_when_compiling_one_block_with_arg_test() {
  [lexer.BlockStart(0, 7, "foo", ["bar", "biz"]), lexer.BlockEnd(0, 7, "foo")]
  |> parser.run(["foo"])
  |> should.be_ok
  |> should.equal([parser.Block("foo", ["bar", "biz"], [])])
}

pub fn parser_should_return_correct_when_compiling_one_without_arg_test() {
  [lexer.BlockStart(0, 7, "foo", []), lexer.BlockEnd(0, 7, "foo")]
  |> parser.run(["foo"])
  |> should.be_ok
  |> should.equal([parser.Block("foo", [], [])])
}

pub fn parser_should_return_error_when_providing_no_end_block_test() {
  [lexer.BlockStart(0, 8, "foo", [])]
  |> parser.run(["foo"])
  |> should.be_error
  |> should.equal([parser.UnbalancedBlock(-1, -1, "foo")])
}

pub fn parser_should_return_error_when_providing_unknown_block_kind_test() {
  [lexer.BlockStart(0, 8, "foo", [])]
  |> parser.run([])
  |> should.be_error
  |> should.equal([parser.UnknownBlockKind(0, 8, "foo")])
}
