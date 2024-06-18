import gleeunit/should
import handles/format
import handles/internal/tokenizer

pub fn format_should_return_correct_string_for_unexpected_token_test() {
  let template = "{{foo}d"
  tokenizer.run(template, 0, [])
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal("Tag is missing closing braces }} (row=0, col=2)")
}

pub fn format_should_return_correct_string_for_unexpected_end_of_template_test() {
  let template = "{{foo}"
  tokenizer.run(template, 0, [])
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal("Tag is missing closing braces }} (row=0, col=2)")
}
