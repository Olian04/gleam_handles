import gleam/dict
import gleam/dynamic
import gleeunit/should
import handles

pub fn handles_hello_world_test() {
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

