import gleeunit/should
import handles/internal/parser
import handles/internal/tokenizer

pub fn no_tokens_test() {
  []
  |> parser.run([])
  |> should.equal([])
}

pub fn one_constant_test() {
  [tokenizer.Constant(0, "Hello World")]
  |> parser.run([])
  |> should.equal([parser.Constant(0, "Hello World")])
}

pub fn one_property_test() {
  [tokenizer.Property(0, ["foo", "bar"])]
  |> parser.run([])
  |> should.equal([parser.Property(0, ["foo", "bar"])])
}

pub fn self_tag_test() {
  [tokenizer.Property(0, [])]
  |> parser.run([])
  |> should.equal([parser.Property(0, [])])
}

pub fn one_ifblock_test() {
  [tokenizer.IfBlockStart(0, ["bar", "biz"]), tokenizer.IfBlockEnd(0)]
  |> parser.run([])
  |> should.equal([parser.IfBlock(0, ["bar", "biz"], [])])
}

pub fn one_unlessblock_test() {
  [tokenizer.UnlessBlockStart(0, ["bar", "biz"]), tokenizer.UnlessBlockEnd(0)]
  |> parser.run([])
  |> should.equal([parser.UnlessBlock(0, ["bar", "biz"], [])])
}

pub fn one_eachblock_test() {
  [tokenizer.EachBlockStart(0, ["bar", "biz"]), tokenizer.EachBlockEnd(0)]
  |> parser.run([])
  |> should.equal([parser.EachBlock(0, ["bar", "biz"], [])])
}
