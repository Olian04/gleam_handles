import gleeunit/should
import handles/format
import handles/lexer

pub fn format_should_return_correct_string_for_unexpected_token_test() {
  let template = "{{foo}d"
  should.be_error(lexer.run(template))
  |> format.format_lex_error(template)
  |> should.equal("Tag is missing closing braces }} (row=0, col=2)")
}

pub fn format_should_return_correct_string_for_unexpected_end_of_template_test() {
  let template = "{{foo}"
  should.be_error(lexer.run(template))
  |> format.format_lex_error(template)
  |> should.equal("Tag is missing closing braces }} (row=0, col=2)")
}
