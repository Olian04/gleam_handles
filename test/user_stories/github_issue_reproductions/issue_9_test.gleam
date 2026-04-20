import gleam/dict
import gleam/string_tree
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser
import handles/internal/tokenizer

const root_template = "{{#each parents}}{{>parent_template .}}{{/each}}"

const parent_template = "{{#each children}}{{>child_template .}}\n{{/each}}"

const child_template = "{{name}}"

const input_context = ctx.Dict(
  [
    ctx.Prop(
      "parents",
      ctx.List(
        [
          ctx.Dict(
            [
              ctx.Prop(
                "children",
                ctx.List(
                  [
                    ctx.Dict([ctx.Prop("name", ctx.Str("Knatte"))]),
                    ctx.Dict([ctx.Prop("name", ctx.Str("Fnatte"))]),
                    ctx.Dict([ctx.Prop("name", ctx.Str("Tjatte"))]),
                  ],
                ),
              ),
            ],
          ),
          ctx.Dict(
            [
              ctx.Prop(
                "children",
                ctx.List(
                  [
                    ctx.Dict([ctx.Prop("name", ctx.Str("Huey"))]),
                    ctx.Dict([ctx.Prop("name", ctx.Str("Dewey"))]),
                    ctx.Dict([ctx.Prop("name", ctx.Str("Louie"))]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ],
)

const expected_output = "Knatte\nFnatte\nTjatte\nHuey\nDewey\nLouie\n"

pub fn nested_partials_test() {
  let root_template =
    tokenizer.run(root_template)
    |> should.be_ok
    |> parser.run
    |> should.be_ok

  let parent_template =
    tokenizer.run(parent_template)
    |> should.be_ok
    |> parser.run
    |> should.be_ok

  let child_template =
    tokenizer.run(child_template)
    |> should.be_ok
    |> parser.run
    |> should.be_ok

  engine.run(
    root_template,
    input_context,
    dict.from_list([
      #("parent_template", parent_template),
      #("child_template", child_template),
    ]),
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal(expected_output)
}
