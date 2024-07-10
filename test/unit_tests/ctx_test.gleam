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
  |> ctx_utils.get(["prop"], _, 0)
  |> should.be_ok
  |> should.equal(ctx.Str(expected_string))
}

pub fn drill_deep_test() {
  let depth = 10_000
  iterator.repeat("prop")
  |> iterator.take(depth)
  |> iterator.to_list
  |> ctx_utils.get(gen_levels(depth), 0)
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
