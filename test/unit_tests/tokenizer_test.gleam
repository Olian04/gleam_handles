import gleeunit/should
import handles/error
import handles/internal/tokenizer

pub fn empty_string_test() {
  ""
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([])
}

pub fn one_tag_test() {
  "{{foo}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, ["foo"])])
}

pub fn two_tags_test() {
  "{{foo}} {{bar}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.Property(2, ["foo"]),
    tokenizer.Constant(7, " "),
    tokenizer.Property(10, ["bar"]),
  ])
}

pub fn self_tag_test() {
  "{{.}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, [])])
}

pub fn unexpected_token_test() {
  "{{foo}d"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn unexpected_end_of_template_test() {
  "{{foo}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn missing_block_argument_test() {
  "{{#if}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingBlockArgument(2))
}

pub fn end_block_with_arguments_test() {
  "{{/if bar}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnexpectedBlockArgument(2))
}

pub fn empty_expression_test() {
  "{{}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingPropertyPath(2))
}
