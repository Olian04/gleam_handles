import gleeunit/should
import parser

pub fn parser_should_return_correct_when_parsing_empty_string_test() {
  parser.parse("")
  |> should.be_ok
  |> should.be_ok
  |> should.equal([parser.Constant(0, 0, "")])
}

pub fn parser_should_return_correct_when_parsing_hello_world_test() {
  parser.parse("Hello {{name}}!")
  |> should.be_ok
  |> should.be_ok
  |> should.equal([
    parser.Constant(0, 6, "Hello "),
    parser.Expression(8, 12, "name"),
    parser.Constant(14, 15, "!"),
  ])
}

pub fn parser_should_return_correct_when_passed_one_tag_test() {
  parser.parse("{{foo}}")
  |> should.be_ok
  |> should.be_ok
  |> should.equal([
    parser.Constant(0, 0, ""),
    parser.Expression(2, 5, "foo"),
    parser.Constant(7, 7, ""),
  ])
}

pub fn parser_should_return_correct_when_passed_two_tags_test() {
  parser.parse("{{foo}} {{bar}}")
  |> should.be_ok
  |> should.be_ok
  |> should.equal([
    parser.Constant(0, 0, ""),
    parser.Expression(2, 5, "foo"),
    parser.Constant(7, 8, " "),
    parser.Expression(10, 13, "bar"),
    parser.Constant(15, 15, ""),
  ])
}

pub fn parser_should_return_parse_error_when_unexpected_token_test() {
  parser.parse("{{foo}d")
  |> should.be_error
  |> should.equal(parser.UnexpectedToken(6, "d"))
}

pub fn parser_should_return_parse_error_when_unexpected_end_of_template_test() {
  parser.parse("{{foo}")
  |> should.be_error
  |> should.equal(parser.UnexpectedEof(6))
}

pub fn compiler_should_return_error_when_missing_block_kind_test() {
  parser.parse("{{#}}")
  |> should.be_ok
  |> should.be_error
  |> should.equal([parser.MissingBlockKind(2, 3)])
}

pub fn compiler_should_return_error_when_providing_arguments_to_end_block_test() {
  parser.parse("{{/foo bar}}")
  |> should.be_ok
  |> should.be_error
  |> should.equal([parser.UnexpectedBlockArgument(2, 10)])
}

pub fn compiler_should_return_error_when_providing_empty_expression_test() {
  parser.parse("{{}}")
  |> should.be_ok
  |> should.be_error
  |> should.equal([parser.EmptyExpression(2, 2)])
}
