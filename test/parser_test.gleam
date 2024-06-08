import gleam/iterator
import gleeunit/should
import parser

pub fn parser_should_return_correct_ast_when_parsing_empty_string_test() {
  let li =
    should.be_ok(parser.parse(""))
    |> iterator.to_list

  should.equal(li, [parser.Template(0, 0, "")])
}

pub fn parser_should_return_correct_ast_when_parsing_hello_world_test() {
  let li =
    should.be_ok(parser.parse("Hello {{name}}!"))
    |> iterator.to_list

  should.equal(li, [
    parser.Template(0, 6, "Hello "),
    parser.Expression(8, 12, "name"),
    parser.Template(14, 15, "!"),
  ])
}

pub fn parser_should_return_correct_ast_when_passed_one_tag_test() {
  let li =
    should.be_ok(parser.parse("{{foo}}"))
    |> iterator.to_list

  should.equal(li, [
    parser.Template(0, 0, ""),
    parser.Expression(2, 5, "foo"),
    parser.Template(7, 7, ""),
  ])
}

pub fn parser_should_return_correct_ast_when_passed_two_tags_test() {
  let li =
    should.be_ok(parser.parse("{{foo}} {{bar}}"))
    |> iterator.to_list

  should.equal(li, [
    parser.Template(0, 0, ""),
    parser.Expression(2, 5, "foo"),
    parser.Template(7, 8, " "),
    parser.Expression(10, 13, "bar"),
    parser.Template(15, 15, ""),
  ])
}

pub fn parser_should_return_parse_error_when_unexpected_token_test() {
  let template = "{{foo}d"
  let err = should.be_error(parser.parse(template))

  should.equal(err, parser.UnexpectedToken(6, "d"))
}

pub fn parser_should_return_parse_error_when_unexpected_end_of_template_test() {
  let template = "{{foo}"
  let err = should.be_error(parser.parse(template))

  should.equal(err, parser.UnexpectedEof(6))
}
