import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser

pub fn hello_world_test() {
  [parser.Constant(0, "Hello World")]
  |> engine.run(ctx.Dict([]), string_builder.new())
  |> should.be_ok
  |> should.equal("Hello World")
}

pub fn hello_name_test() {
  [parser.Constant(0, "Hello "), parser.Property(0, ["name"])]
  |> engine.run(
    ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("Hello Oliver")
}

pub fn self_tag_test() {
  [parser.Property(0, [])]
  |> engine.run(ctx.Str("Hello"), string_builder.new())
  |> should.be_ok
  |> should.equal("Hello")
}

pub fn nested_property_test() {
  [parser.Property(0, ["foo", "bar"])]
  |> engine.run(
    ctx.Dict([ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))]))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("42")
}

pub fn truthy_if_test() {
  [parser.IfBlock(0, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([
      ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))])),
      ctx.Prop("bool", ctx.Bool(True)),
    ]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("42")
}

pub fn falsy_if_test() {
  [parser.IfBlock(0, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([ctx.Prop("bool", ctx.Bool(False))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn truthy_unless_test() {
  [parser.UnlessBlock(0, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([ctx.Prop("bool", ctx.Bool(True))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn falsy_unless_test() {
  [parser.UnlessBlock(0, ["bool"], [parser.Property(0, ["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([
      ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))])),
      ctx.Prop("bool", ctx.Bool(False)),
    ]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("42")
}

pub fn each_test() {
  [
    parser.Constant(0, "They are "),
    parser.EachBlock(0, ["list"], [
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
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("They are Knatte, Fnatte, Tjatte, and Kalle")
}

pub fn empty_each_test() {
  [
    parser.EachBlock(0, ["list"], [
      parser.Property(0, ["name"]),
      parser.Constant(0, ", "),
    ]),
  ]
  |> engine.run(
    ctx.Dict([ctx.Prop("list", ctx.List([]))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}
