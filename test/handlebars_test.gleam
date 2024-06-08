import gleam/iterator
import gleam/result
import gleeunit
import gleeunit/should
import parser

pub fn main() {
  gleeunit.main()
}

pub fn parser_should_return_ast_with_one_element_when_parsing_empty_string_test() {
  use iter <- result.map(parser.parse(""))
  let li = iter |> iterator.to_list

  should.equal(li, [parser.Template(0, 0, "")])
}

pub fn parser_should_return_ast_with_two_elements_when_passed_empty_template_with_one_tag_test() {
  use iter <- result.map(parser.parse("{{foo}}"))
  let li = iter |> iterator.to_list

  should.equal(li, [
    parser.Template(0, 0, ""),
    parser.Expression(2, 5, "foo"),
    parser.Template(7, 7, ""),
  ])
}
