[![Package Version](https://img.shields.io/hexpm/v/handlebars)](https://hex.pm/packages/handlebars)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/handlebars/)

# handles

`handles` is a templating language written in pure Gleam. Heavily inspired by [mustache](https://mustache.github.io/) and [Handlebars.js](https://github.com/handlebars-lang/handlebars.js).

```sh
gleam add handles
```

```gleam
import handles
import gleam/io
import gleam/dict
import gleam/dynamic

pub fn main() {
  let assert Ok(template) = handles.prepare("Hello {{name}}")
  let assert Ok(string) =
    handles.run(
      template,
      dict.new()
        |> dict.insert("name", "Oliver")
        |> dynamic.from,
    )

  io.println(string)
}
```

## Usage Documentation

__Handles__ a is very simple templating language that consists of a single primitive, the "tag".
A tag starts with two open braces `{{`, followed by a string body, and ends with two closing braces `}}`.
There are two kinds of tags, [Property tags](#property-tags) and [Block tags](#block-tags).

### Property tags

A property tag is used to access properties passed into the template engine and insert them into the resulting string in-place of the property tag.
Values accessed by a property tag must be of type `String`, `Int`, or `Float`, or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.

```handlebars
{{some.property.path}}
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
Values accessed by an `each` block must be of type `List(Dict)` or it will result in a runtime error.
Accessing a property which was not passed into the template engine will result in a runtime error.
The context of which properties are resolved while inside the each block will be scoped to the current item from the list.

```handlebars
{{#each some.prop}}
  {{name}}
{{/each}}
```

Further documentation can be found at <https://hexdocs.pm/handles>.

## Development

```sh
gleam test
```
