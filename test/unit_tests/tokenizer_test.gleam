import gleeunit/should
import handles/error
import handles/internal/tokenizer

pub fn tokenizer_should_return_correct_when_parsing_empty_string_test() {
  ""
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([])
}

pub fn tokenizer_should_return_correct_when_passed_one_tag_test() {
  "{{foo}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.Property(["foo"])])
}

pub fn tokenizer_should_return_correct_when_passed_two_tags_test() {
  "{{foo}} {{bar}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.Property(["foo"]),
    tokenizer.Constant(" "),
    tokenizer.Property(["bar"]),
  ])
}

pub fn tokenizer_should_return_lex_error_when_unexpected_token_test() {
  "{{foo}d"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn tokenizer_should_return_lex_error_when_unexpected_end_of_template_test() {
  "{{foo}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn compiler_should_return_error_when_missing_block_kind_test() {
  "{{#if}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingBlockArgument(2))
}

pub fn compiler_should_return_error_when_providing_arguments_to_end_block_test() {
  "{{/if bar}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnexpectedBlockArgument(2))
}

pub fn compiler_should_return_error_when_providing_empty_expression_test() {
  "{{}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingPropertyPath(2))
}
