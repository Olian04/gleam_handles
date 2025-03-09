import gleam/dict
import gleam/string_tree
import gleeunit/should
import handles/ctx
import handles/internal/block
import handles/internal/engine
import handles/internal/parser

pub fn hello_world_test() {
  [parser.Constant(0, "Hello World")]
  |> engine.run(ctx.Dict([]), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello World")
}

pub fn hello_name_test() {
  [parser.Constant(0, "Hello "), parser.Property(0, ["name"])]
  |> engine.run(ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))]), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello Oliver")
}

pub fn self_tag_test() {
  [parser.Property(0, [])]
  |> engine.run(ctx.Str("Hello"), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("Hello")
}

pub fn nested_property_test() {
  [parser.Property(0, ["foo", "bar"])]
  |> engine.run(
    ctx.Dict([ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))]))]),
    dict.new(),
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("42")
}

pub fn truthy_if_test() {
  [parser.Block(0, 0, block.If, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([
      ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))])),
      ctx.Prop("bool", ctx.Bool(True)),
    ]),
    dict.new(),
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("42")
}

pub fn falsy_if_test() {
  [parser.Block(0, 0, block.If, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(ctx.Dict([ctx.Prop("bool", ctx.Bool(False))]), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("")
}

pub fn truthy_unless_test() {
  [
    parser.Block(0, 0, block.Unless, ["bool"], [
      parser.Property(0, ["foo", "bar"]),
    ]),
  ]
  |> engine.run(ctx.Dict([ctx.Prop("bool", ctx.Bool(True))]), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("")
}

pub fn falsy_unless_test() {
  [
    parser.Block(0, 0, block.Unless, ["bool"], [
      parser.Property(0, ["foo", "bar"]),
    ]),
  ]
  |> engine.run(
    ctx.Dict([
      ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))])),
      ctx.Prop("bool", ctx.Bool(False)),
    ]),
    dict.new(),
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("42")
}

pub fn each_test() {
  [
    parser.Constant(0, "They are "),
    parser.Block(0, 0, block.Each, ["list"], [
      parser.Property(0, ["name"]),
      parser.Constant(0, ", "),
    ]),
    parser.Constant(0, "and Kalle"),
  ]
  |> engine.run(
    ctx.Dict([
      ctx.Prop(
        "list",
        ctx.List([
          ctx.Dict([ctx.Prop("name", ctx.Str("Knatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Fnatte"))]),
          ctx.Dict([ctx.Prop("name", ctx.Str("Tjatte"))]),
        ]),
      ),
    ]),
    dict.new(),
  )
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("They are Knatte, Fnatte, Tjatte, and Kalle")
}

pub fn empty_each_test() {
  [
    parser.Block(0, 0, block.Each, ["list"], [
      parser.Property(0, ["name"]),
      parser.Constant(0, ", "),
    ]),
  ]
  |> engine.run(ctx.Dict([ctx.Prop("list", ctx.List([]))]), dict.new())
  |> should.be_ok
  |> string_tree.to_string
  |> should.equal("")
}
