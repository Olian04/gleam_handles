import gleam/dict
import gleam/dynamic
import gleam/list
import gleeunit/should
import handles

pub fn api_hello_world_test() {
  handles.prepare("Hello {{name}}")
  |> should.be_ok
  |> handles.run(
    dict.new()
    |> dict.insert("name", "Oliver")
    |> dynamic.from,
  )
  |> should.be_ok
  |> should.equal("Hello Oliver")
}

pub fn api_knattarna_test() {
  handles.prepare("{{#each knattarna}}Hello {{name}}\n{{/each}}")
  |> should.be_ok
  |> handles.run(
    dict.new()
    |> dict.insert(
      "knattarna",
      list.new()
        |> list.append([
          dict.new()
            |> dict.insert("name", "Knatte")
            |> dynamic.from,
          dict.new()
            |> dict.insert("name", "Fnatte")
            |> dynamic.from,
          dict.new()
            |> dict.insert("name", "Tjatte")
            |> dynamic.from,
        ])
        |> dynamic.from,
    )
    |> dynamic.from,
  )
  |> should.be_ok
  |> should.equal(
    "Hello Knatte
Hello Fnatte
Hello Tjatte
",
  )
}
