import gleeunit/should
import handles/error
import handles/internal/block
import handles/internal/tokenizer

pub fn empty_string_test() {
  ""
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([])
}

pub fn property_test() {
  "{{foo}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, ["foo"])])
}

pub fn property_multiple_test() {
  "{{foo}} {{bar}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.Property(2, ["foo"]),
    tokenizer.Constant(7, " "),
    tokenizer.Property(10, ["bar"]),
  ])
}

pub fn property_self_test() {
  "{{.}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, [])])
}

pub fn if_block_test() {
  "{{#if prop}}{{/if}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.If, ["prop"]),
    tokenizer.BlockEnd(14, block.If),
  ])
}

pub fn if_block_self_test() {
  "{{#if .}}{{/if}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.If, []),
    tokenizer.BlockEnd(11, block.If),
  ])
}

pub fn unless_block_test() {
  "{{#unless prop}}{{/unless}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.Unless, ["prop"]),
    tokenizer.BlockEnd(18, block.Unless),
  ])
}

pub fn unless_block_self_test() {
  "{{#unless .}}{{/unless}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.Unless, []),
    tokenizer.BlockEnd(15, block.Unless),
  ])
}

pub fn each_block_test() {
  "{{#each prop}}{{/each}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.Each, ["prop"]),
    tokenizer.BlockEnd(16, block.Each),
  ])
}

pub fn each_block_self_test() {
  "{{#each .}}{{/each}}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.Each, []),
    tokenizer.BlockEnd(13, block.Each),
  ])
}

pub fn unexpected_token_test() {
  "{{foo}d"
  |> tokenizer.run
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn unexpected_end_of_template_test() {
  "{{foo}"
  |> tokenizer.run
  |> should.be_error
  |> should.equal(error.UnbalancedTag(2))
}

pub fn missing_block_argument_test() {
  "{{#if}}"
  |> tokenizer.run
  |> should.be_error
  |> should.equal(error.MissingArgument(2))
}

pub fn end_block_with_arguments_test() {
  "{{/if bar}}"
  |> tokenizer.run
  |> should.be_error
  |> should.equal(error.UnexpectedArgument(2))
}

pub fn empty_expression_test() {
  "{{}}"
  |> tokenizer.run
  |> should.be_error
  |> should.equal(error.MissingArgument(2))
}

pub fn whitespace_test() {
  "{{                  .             }}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([tokenizer.Property(2, [])])

  "{{#             if      prop          }}{{/            if           }}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([
    tokenizer.BlockStart(2, block.If, ["prop"]),
    tokenizer.BlockEnd(42, block.If),
  ])

  "{{>             template      prop          }}"
  |> tokenizer.run
  |> should.be_ok
  |> should.equal([tokenizer.Partial(2, "template", ["prop"])])
}
