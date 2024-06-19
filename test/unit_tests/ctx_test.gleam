import gleam/iterator
import gleeunit/should
import handles/ctx
import handles/internal/ctx_utils

const expected_string = "expected"

fn gen_levels(levels_to_go: Int) {
  case levels_to_go {
    0 -> ctx.Str(expected_string)
    _ -> ctx.Dict([ctx.Prop("prop", gen_levels(levels_to_go - 1))])
  }
}

pub fn drill_shallow_test() {
  ctx.Dict([ctx.Prop("prop", ctx.Str(expected_string))])
  |> ctx_utils.drill_ctx(["prop"], _)
  |> should.be_ok
  |> should.equal(ctx.Str(expected_string))
}

pub fn drill_deep_test() {
  let depth = 100
  iterator.repeat("prop")
  |> iterator.take(depth)
  |> iterator.to_list
  |> ctx_utils.drill_ctx(gen_levels(depth))
  |> should.be_ok
  |> should.equal(ctx.Str(expected_string))
}
