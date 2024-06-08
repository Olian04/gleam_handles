import compiler
import engine
import gleeunit/should

pub fn engine_should_return_correct_when_running_hello_world_test() {
  engine.run([compiler.Constant("Hello World")], fn(_) { "" })
  |> should.be_ok
  |> should.equal("Hello World")
}
