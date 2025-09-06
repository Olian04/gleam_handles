import gleam/list
import gleeunit/should
import handles/ctx
import handles/internal/ctx_utils

const expected_string = "expected"

fn gen_levels(levels_to_go: Int, curr: ctx.Value) -> ctx.Value {
  case levels_to_go {
    0 -> curr
    _ -> gen_levels(levels_to_go - 1, ctx.Dict([ctx.Prop("prop", curr)]))
  }
}

pub fn drill_shallow_test() {
  ctx.Dict([ctx.Prop("prop", ctx.Str(expected_string))])
  |> ctx_utils.get(["prop"], _, 0)
  |> should.be_ok
  |> should.equal(ctx.Str(expected_string))
}

pub fn drill_deep_test() {
  let depth = 10_000
  list.repeat("prop", depth)
  |> ctx_utils.get(gen_levels(depth, ctx.Str(expected_string)), 0)
  |> should.be_ok
  |> should.equal(ctx.Str(expected_string))
}

pub fn get_property_success_test() {
  let ctx =
    ctx.Dict([
      ctx.Prop("name", ctx.Str("Alice")),
      ctx.Prop("age", ctx.Int(30)),
      ctx.Prop("height", ctx.Float(5.9)),
    ])
  ctx_utils.get_property(["name"], ctx, 0)
  |> should.be_ok
  |> should.equal("Alice")

  ctx_utils.get_property(["age"], ctx, 0)
  |> should.be_ok
  |> should.equal("30")

  ctx_utils.get_property(["height"], ctx, 0)
  |> should.be_ok
  |> should.equal("5.9")
}

pub fn get_property_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_property(["unknown"], ctx, 0)
  |> should.be_error

  ctx_utils.get_property(["name", "subprop"], ctx, 0)
  |> should.be_error
}

pub fn get_list_success_test() {
  let ctx =
    ctx.Dict([ctx.Prop("items", ctx.List([ctx.Str("item1"), ctx.Str("item2")]))])
  ctx_utils.get_list(["items"], ctx, 0)
  |> should.be_ok
}

pub fn get_list_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_list(["name"], ctx, 0)
  |> should.be_error
}

pub fn get_bool_success_test() {
  let ctx = ctx.Dict([ctx.Prop("active", ctx.Bool(True))])
  ctx_utils.get_bool(["active"], ctx, 0)
  |> should.be_ok
}

pub fn get_bool_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_bool(["name"], ctx, 0)
  |> should.be_error
}
