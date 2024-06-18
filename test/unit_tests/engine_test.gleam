import gleam/string_builder
import gleeunit/should
import handles/ctx
import handles/internal/engine
import handles/internal/parser

pub fn hello_world_test() {
  [parser.Constant("Hello World")]
  |> engine.run(ctx.Dict([]), string_builder.new())
  |> should.be_ok
  |> should.equal("Hello World")
}

pub fn hello_name_test() {
  [parser.Constant("Hello "), parser.Property(["name"])]
  |> engine.run(
    ctx.Dict([ctx.Prop("name", ctx.Str("Oliver"))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("Hello Oliver")
}

pub fn nested_property_test() {
  [parser.Property(["foo", "bar"])]
  |> engine.run(
    ctx.Dict([ctx.Prop("foo", ctx.Dict([ctx.Prop("bar", ctx.Int(42))]))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("42")
}

pub fn truthy_if_test() {
  [parser.IfBlock(["bool"], [parser.Property(["foo", "bar"])])]
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
  [parser.IfBlock(["bool"], [parser.Property(["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([ctx.Prop("bool", ctx.Bool(False))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn truthy_unless_test() {
  [parser.UnlessBlock(["bool"], [parser.Property(["foo", "bar"])])]
  |> engine.run(
    ctx.Dict([ctx.Prop("bool", ctx.Bool(True))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}

pub fn falsy_unless_test() {
  [parser.UnlessBlock(["bool"], [parser.Property(["foo", "bar"])])]
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
    parser.Constant("They are "),
    parser.EachBlock(["list"], [
      parser.Property(["name"]),
      parser.Constant(", "),
    ]),
    parser.Constant("and Kalle"),
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
    parser.EachBlock(["list"], [
      parser.Property(["name"]),
      parser.Constant(", "),
    ]),
  ]
  |> engine.run(
    ctx.Dict([ctx.Prop("list", ctx.List([]))]),
    string_builder.new(),
  )
  |> should.be_ok
  |> should.equal("")
}
