import gleam/json
import gleam/list
import gleeunit/should
import handles/ctx

// Reproduction for GitHub issue #11:
// Json encoding for context values.
// https://github.com/Olian04/gleam_handles/issues/11

const input_context = ctx.Dict(
  [ctx.Prop("name", ctx.Str("John")), ctx.Prop("age", ctx.Int(30))],
)

const expected_output = "{\"name\":\"John\",\"age\":30}"

pub fn json_encoding_test() {
  input_context
  |> to_json
  |> should.equal(expected_output)
}

fn to_json(ctx: ctx.Value) -> String {
  ctx
  |> to_json_value
  |> json.to_string
}

fn to_json_value(ctx: ctx.Value) -> json.Json {
  case ctx {
    ctx.Str(value) -> json.string(value)
    ctx.Int(value) -> json.int(value)
    ctx.Float(value) -> json.float(value)
    ctx.Bool(value) -> json.bool(value)
    ctx.Dict(props) ->
      props
      |> list.map(fn(prop) { #(prop.key, to_json_value(prop.value)) })
      |> json.object
    ctx.List(values) -> json.array(values, to_json_value)
  }
}
