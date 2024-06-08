import format
import gleeunit/should
import parser

pub fn format_should_return_correct_string_for_unexpected_token_test() {
  let template = "{{foo}d"
  let err = should.be_error(parser.parse(template))

  should.equal(
    format.parse_error(err, template),
    "Unexpected token (row=0, col=6): d",
  )
}

pub fn format_should_return_correct_string_for_unexpected_end_of_template_test() {
  let template = "{{foo}"
  let err = should.be_error(parser.parse(template))

  should.equal(
    format.parse_error(err, template),
    "Unexpected end of template (row=0, col=6)",
  )
}
