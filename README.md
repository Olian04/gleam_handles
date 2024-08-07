[![Package Version](https://img.shields.io/hexpm/v/handles)](https://hex.pm/packages/handles)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/handles/)

# handles

`handles` is a templating language written in pure Gleam. Heavily inspired by [mustache](https://mustache.github.io/) and [Handlebars.js](https://github.com/handlebars-lang/handlebars.js).

```sh
gleam add handles
```

```gleam
import gleam/io
import gleam/string_builder
import handles
import handles/ctx

pub fn main() {
  let assert Ok(greet_template) = handles.prepare("Hello {{.}}!")
  let assert Ok(template) =
    handles.prepare("{{>greet world}}\n{{>greet community}}\n{{>greet you}}")
  let assert Ok(string) =
    handles.run(
      template,
      ctx.Dict([
        ctx.Prop("world", ctx.Str("World")),
        ctx.Prop("community", ctx.Str("Gleam Community")),
        ctx.Prop("you", ctx.Str("YOU")),
      ]),
      [#("greet", greet_template)],
    )

  string
  |> string_builder.to_string
  |> io.println
}
```

Further documentation can be found at <https://hexdocs.pm/handles>.

## Usage Documentation

__Handles__ a is very simple templating language that consists of a single primitive, the "tag".
A tag starts with two open braces `{{`, followed by a string body, and ends with two closing braces `}}`.
There are three kinds of tags, [Property tags](#property-tags), [Block tags](#block-tags), and [Partial tags](#partial-tags).

### Property tags

A property tag is used to access properties passed into the template engine and insert them into the resulting string in-place of the property tag.
Values accessed by a property tag must be of type `String`, `Int`, or `Float`, or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.

A property tag can refer to a nested property with `.` separating keys in nested dicts.

```handlebars
{{some.property.path}}
```

A property can also refer to the current context element by passing a single `.`.

```handlebars
{{.}}
```

### Block tags

A block tag is used to temporarily alter the behavior of the templating engine.
Each block tag have two variants; A start tag indicated by a leading `#` and a stop tag indicated by a leading `/`.
A blocks start tag accepts a property accessor, while the end tag does not.

#### if

`if` blocks are used to conditionally _include_ parts of a templated based on the value of a property.
Values accessed by an if block must be of type `Bool` or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.

```handlebars
{{#if some.prop}}
  {{name}}
{{/if}}
```

#### unless

`unless` blocks are used to conditionally _exclude_ parts of a templated based on the value of a property.
Values accessed by an `unless` block must be of type `Bool` or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.

```handlebars
{{#unless some.prop}}
  {{name}}
{{/unless}}
```

#### each

`each` blocks are used to include a part of a templated zero or more times.
Values accessed by an `each` block must be of type `List` or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.
The context of which properties are resolved while inside the each block will be scoped to the current item from the list.

```handlebars
{{#each some.prop}}
  {{name}}
{{/each}}
```

### Partial tags

A partial tag is used to include other templates in-place of the partial tag.
Values accessed by a partial tag can be of any type and will be passed to the partial as the context of which properties are resolved against while inside the partial template.
Accessing a property which was not passed into the template engine will result in a runtime error.

```handlebars
{{>some_template some.prop.path}}
```

## Development

The source code is structured in such a way that the compiled output when targeting JS does not use recursion in the main parts of the library (`tokenizer.gleam`, `parser.gleam`, `engine.gleam` & `ctx_utils.gleam`). This prevents the JS engine from throwing "Maximum call stack size exceeded" for regular use-cases. While most JS engines boast about implementing tail call optimization, the Gleam compiler is not yet advanced enough to properly take advantage of this. There for, any changes made to the code will need to be carefully inspected after compiling to JS to make sure that no recursion is introduced. This behavior is likely to change with changes to the Gleam compiler, so whenever a new version of the Gleam compiler is released, this library will need to be recompiled and checked (at least until the Gleam compiler becomes smart enough to properly utilize TCO in JS).

Latest Gleam compiler version checked: `1.3.2`

Known recursion that needs to be resolved:

* Parsing the body of a block in `parser.gleam`

### Running in development

```sh
gleam test # Test Erlang
gleam test -t js # Test Nodejs
```
