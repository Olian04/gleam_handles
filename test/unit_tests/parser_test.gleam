import gleeunit/should
import handles/internal/parser
import handles/internal/tokenizer

pub fn parser_should_return_correct_when_compiling_no_tokens_test() {
  []
  |> parser.run([])
  |> should.equal([])
}

pub fn parser_should_return_correct_when_compiling_one_constant_test() {
  [tokenizer.Constant("Hello World")]
  |> parser.run([])
  |> should.equal([parser.Constant("Hello World")])
}

pub fn parser_should_return_correct_when_compiling_one_property_test() {
  [tokenizer.Property(["foo", "bar"])]
  |> parser.run([])
  |> should.equal([parser.Property(["foo", "bar"])])
}

pub fn parser_should_return_correct_when_compiling_one_ifblock_test() {
  [tokenizer.IfBlockStart(["bar", "biz"]), tokenizer.IfBlockEnd]
  |> parser.run([])
  |> should.equal([parser.IfBlock(["bar", "biz"], [])])
}

pub fn parser_should_return_correct_when_compiling_one_unlessblock_test() {
  [tokenizer.UnlessBlockStart(["bar", "biz"]), tokenizer.UnlessBlockEnd]
  |> parser.run([])
  |> should.equal([parser.UnlessBlock(["bar", "biz"], [])])
}

pub fn parser_should_return_correct_when_compiling_one_eachblock_test() {
  [tokenizer.EachBlockStart(["bar", "biz"]), tokenizer.EachBlockEnd]
  |> parser.run([])
  |> should.equal([parser.EachBlock(["bar", "biz"], [])])
}
