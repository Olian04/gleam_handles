import gleeunit/should
import handles/error
import handles/internal/tokenizer

pub fn empty_string_test() {
  ""
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([])
}

pub fn property_test() {
  "{{foo}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, ["foo"])])
}

pub fn property_multiple_test() {
  "{{foo}} {{bar}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.Property(2, ["foo"]),
    tokenizer.Constant(7, " "),
    tokenizer.Property(10, ["bar"]),
  ])
}

pub fn property_self_test() {
  "{{.}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, [])])
}

pub fn if_block_test() {
  "{{#if prop}}{{/if}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.IfBlockStart(2, ["prop"]),
    tokenizer.IfBlockEnd(14),
  ])
}

pub fn if_block_self_test() {
  "{{#if .}}{{/if}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.IfBlockStart(2, []), tokenizer.IfBlockEnd(11)])
}

pub fn unless_block_test() {
  "{{#unless prop}}{{/unless}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.UnlessBlockStart(2, ["prop"]),
    tokenizer.UnlessBlockEnd(18),
  ])
}

pub fn unless_block_self_test() {
  "{{#unless .}}{{/unless}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.UnlessBlockStart(2, []),
    tokenizer.UnlessBlockEnd(15),
  ])
}

pub fn each_block_test() {
  "{{#each prop}}{{/each}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([
    tokenizer.EachBlockStart(2, ["prop"]),
    tokenizer.EachBlockEnd(16),
  ])
}

pub fn each_block_self_test() {
  "{{#each .}}{{/each}}"
  |> tokenizer.run(0, [])
  |> should.be_ok
  |> should.equal([tokenizer.EachBlockStart(2, []), tokenizer.EachBlockEnd(13)])
}

pub fn unexpected_token_test() {
  "{{foo}d"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn unexpected_end_of_template_test() {
  "{{foo}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn missing_block_argument_test() {
  "{{#if}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingBlockArgument(2))
}

pub fn end_block_with_arguments_test() {
  "{{/if bar}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.UnexpectedBlockArgument(2))
}

pub fn empty_expression_test() {
  "{{}}"
  |> tokenizer.run(0, [])
  |> should.be_error
  |> should.equal(error.MissingPropertyPath(2))
}
