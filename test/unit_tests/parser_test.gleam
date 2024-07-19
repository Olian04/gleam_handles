import gleeunit/should
import handles/error
import handles/internal/block
import handles/internal/parser
import handles/internal/tokenizer

pub fn no_tokens_test() {
  []
  |> parser.run
  |> should.be_ok
  |> should.equal([])
}

pub fn one_constant_test() {
  [tokenizer.Constant(0, "Hello World")]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Constant(0, "Hello World")])
}

pub fn one_property_test() {
  [tokenizer.Property(0, ["foo", "bar"])]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Property(0, ["foo", "bar"])])
}

pub fn self_tag_test() {
  [tokenizer.Property(0, [])]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Property(0, [])])
}

pub fn one_ifblock_test() {
  [
    tokenizer.BlockStart(0, block.If, ["bar", "biz"]),
    tokenizer.BlockEnd(0, block.If),
  ]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Block(0, 0, block.If, ["bar", "biz"], [])])
}

pub fn one_unlessblock_test() {
  [
    tokenizer.BlockStart(0, block.Unless, ["bar", "biz"]),
    tokenizer.BlockEnd(0, block.Unless),
  ]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Block(0, 0, block.Unless, ["bar", "biz"], [])])
}

pub fn one_eachblock_test() {
  [
    tokenizer.BlockStart(0, block.Each, ["bar", "biz"]),
    tokenizer.BlockEnd(0, block.Each),
  ]
  |> parser.run
  |> should.be_ok
  |> should.equal([parser.Block(0, 0, block.Each, ["bar", "biz"], [])])
}

pub fn missing_if_block_end_test() {
  [tokenizer.BlockStart(0, block.If, [])]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnbalancedBlock(0))
}

pub fn missing_unless_block_end_test() {
  [tokenizer.BlockStart(0, block.Unless, [])]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnbalancedBlock(0))
}

pub fn missing_each_block_end_test() {
  [tokenizer.BlockStart(0, block.Each, [])]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnbalancedBlock(0))
}

pub fn missing_if_block_start_test() {
  [tokenizer.BlockEnd(0, block.If)]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnexpectedBlockEnd(0))
}

pub fn missing_unless_block_start_test() {
  [tokenizer.BlockEnd(0, block.Unless)]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnexpectedBlockEnd(0))
}

pub fn missing_each_block_start_test() {
  [tokenizer.BlockEnd(0, block.Unless)]
  |> parser.run
  |> should.be_error
  |> should.equal(error.UnexpectedBlockEnd(0))
}
