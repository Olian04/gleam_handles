import handles/format
import gleeunit/should
import handles/parser

pub fn format_should_return_correct_string_for_unexpected_token_test() {
  let template = "{{foo}d"
  should.be_error(parser.parse(template))
  |> format.format_parse_error(template)
  |> should.equal("Unexpected token (row=0, col=6): d")
}

pub fn format_should_return_correct_string_for_unexpected_end_of_template_test() {
  let template = "{{foo}"
  should.be_error(parser.parse(template))
  |> format.format_parse_error(template)
  |> should.equal("Unexpected end of template (row=0, col=6)")
}
