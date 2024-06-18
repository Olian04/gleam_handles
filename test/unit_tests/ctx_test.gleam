import gleam/dict
import gleam/dynamic
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

pub fn from_string_test() {
  ctx.from("foo")
  |> should.equal(ctx.Str("foo"))
}

pub fn from_int_test() {
  ctx.from(42)
  |> should.equal(ctx.Int(42))
}

pub fn from_float_test() {
  ctx.from(3.14)
  |> should.equal(ctx.Float(3.14))
}

pub fn from_bool_test() {
  ctx.from(True)
  |> should.equal(ctx.Bool(True))
}

pub fn from_list_test() {
  ctx.from([1, 2, 3])
  |> should.equal(ctx.List([ctx.Int(1), ctx.Int(2), ctx.Int(3)]))
}

pub fn from_dict_test() {
  ctx.from(
    dict.new()
    |> dict.insert("first", 1)
    |> dict.insert("second", 2)
    |> dict.insert("third", 3),
  )
  |> should.equal(
    ctx.Dict([
      ctx.Prop("first", ctx.Int(1)),
      ctx.Prop("second", ctx.Int(2)),
      ctx.Prop("third", ctx.Int(3)),
    ]),
  )
}

pub fn from_mixed_types_test() {
  ctx.from([42 |> dynamic.from, 3.14 |> dynamic.from, "Hello" |> dynamic.from])
  |> should.equal(ctx.List([ctx.Int(42), ctx.Float(3.14), ctx.Str("Hello")]))
}
