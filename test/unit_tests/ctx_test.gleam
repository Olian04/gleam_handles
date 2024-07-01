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

pub fn get_property_success_test() {
  let ctx =
    ctx.Dict([
      ctx.Prop("name", ctx.Str("Alice")),
      ctx.Prop("age", ctx.Int(30)),
      ctx.Prop("height", ctx.Float(5.9)),
    ])
  ctx_utils.get_property(0, ["name"], ctx)
  |> should.be_ok
  |> should.equal("Alice")

  ctx_utils.get_property(0, ["age"], ctx)
  |> should.be_ok
  |> should.equal("30")

  ctx_utils.get_property(0, ["height"], ctx)
  |> should.be_ok
  |> should.equal("5.9")
}

pub fn get_property_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_property(0, ["unknown"], ctx)
  |> should.be_error

  ctx_utils.get_property(0, ["name", "subprop"], ctx)
  |> should.be_error
}

pub fn get_list_success_test() {
  let ctx =
    ctx.Dict([ctx.Prop("items", ctx.List([ctx.Str("item1"), ctx.Str("item2")]))])
  ctx_utils.get_list(0, ["items"], ctx)
  |> should.be_ok
}

pub fn get_list_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_list(0, ["name"], ctx)
  |> should.be_error
}

pub fn get_bool_success_test() {
  let ctx = ctx.Dict([ctx.Prop("active", ctx.Bool(True))])
  ctx_utils.get_bool(0, ["active"], ctx)
  |> should.be_ok
}

pub fn get_bool_error_test() {
  let ctx = ctx.Dict([ctx.Prop("name", ctx.Str("Alice"))])
  ctx_utils.get_bool(0, ["name"], ctx)
  |> should.be_error
}
