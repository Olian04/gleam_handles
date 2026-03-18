import gleeunit/should
import handles/format
import handles/internal/tokenizer

pub fn unexpected_token_test() {
  let template = "{{foo}d"
  tokenizer.run(template)
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal(
    "Tag is missing closing braces }} (row=0, col=2)\nNear:\n{{foo}d\n  ^",
  )
}

pub fn unexpected_end_of_template_test() {
  let template = "{{foo}"
  tokenizer.run(template)
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal(
    "Tag is missing closing braces }} (row=0, col=2)\nNear:\n{{foo}\n  ^",
  )
}

pub fn unexpected_multiple_arguments_test() {
  let template = "{{#if foo bar}}"
  tokenizer.run(template)
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal(
    "Tag is receiving too many arguments (row=0, col=2)\nNear:\n{{#if foo bar}}\n  ^",
  )
}

pub fn unexpected_block_kind_test() {
  let template = "{{#unexpected foo}}"
  tokenizer.run(template)
  |> should.be_error
  |> format.format_tokenizer_error(template)
  |> should.be_ok
  |> should.equal(
    "Tag is of an unknown block kind (row=0, col=2)\nNear:\n{{#unexpected foo}}\n  ^",
  )
}
