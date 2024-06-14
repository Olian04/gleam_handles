import gleeunit/should
import handles/lexer

pub fn lexer_should_return_correct_when_parsing_empty_string_test() {
  lexer.run("")
  |> should.be_ok
  |> should.equal([lexer.Constant(0, 0, "")])
}

pub fn lexer_should_return_correct_when_parsing_hello_world_test() {
  lexer.run("Hello {{name}}!")
  |> should.be_ok
  |> should.equal([
    lexer.Constant(0, 6, "Hello "),
    lexer.Property(8, 12, ["name"]),
    lexer.Constant(14, 15, "!"),
  ])
}

pub fn lexer_should_return_correct_when_passed_one_tag_test() {
  lexer.run("{{foo}}")
  |> should.be_ok
  |> should.equal([
    lexer.Constant(0, 0, ""),
    lexer.Property(2, 5, ["foo"]),
    lexer.Constant(7, 7, ""),
  ])
}

pub fn lexer_should_return_correct_when_passed_two_tags_test() {
  lexer.run("{{foo}} {{bar}}")
  |> should.be_ok
  |> should.equal([
    lexer.Constant(0, 0, ""),
    lexer.Property(2, 5, ["foo"]),
    lexer.Constant(7, 8, " "),
    lexer.Property(10, 13, ["bar"]),
    lexer.Constant(15, 15, ""),
  ])
}

pub fn lexer_should_return_lex_error_when_unexpected_token_test() {
  lexer.run("{{foo}d")
  |> should.be_error
  |> should.equal(lexer.UnbalancedTag(2, 7))
}

pub fn lexer_should_return_lex_error_when_unexpected_end_of_template_test() {
  lexer.run("{{foo}")
  |> should.be_error
  |> should.equal(lexer.UnbalancedTag(2, 6))
}

pub fn compiler_should_return_error_when_missing_block_kind_test() {
  lexer.run("{{#}}")
  |> should.be_error
  |> should.equal(lexer.SyntaxError([lexer.MissingBlockKind(2, 3)]))
}

pub fn compiler_should_return_error_when_providing_arguments_to_end_block_test() {
  lexer.run("{{/foo bar}}")
  |> should.be_error
  |> should.equal(lexer.SyntaxError([lexer.UnexpectedBlockArgument(2, 10)]))
}

pub fn compiler_should_return_error_when_providing_empty_expression_test() {
  lexer.run("{{}}")
  |> should.be_error
  |> should.equal(lexer.SyntaxError([lexer.MissingBody(2, 2)]))
}
