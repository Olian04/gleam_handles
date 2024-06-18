import gleam/dict
import gleam/dynamic
import gleam/list

pub type Prop {
  Prop(key: String, value: Value)
}

pub type Value {
  Str(value: String)
  Int(value: Int)
  Float(value: Float)
  Bool(value: Bool)
  Dict(value: List(Prop))
  List(value: List(Value))
}

/// Transforms String, Int, Float, Bool, List, & Dict to their coresponding ctx.Value type.
/// 
/// Anny other types will panic
/// 
/// ## Examples
/// 
/// ```gleam
/// import handles/ctx
/// 
/// ctx.from("Hello World")
/// // -> ctx.Str("Hello World")
/// ```
///
/// ```gleam
/// ctx.from(42)
/// // -> ctx.Int(42)
/// ```
/// 
/// ```gleam
/// ctx.from(3.14)
/// // -> ctx.Float(3.14)
/// ```
/// 
/// ```gleam
/// ctx.from([1, 2, 3])
/// // -> ctx.List([ctx.Int(1), ctx.Int(2), ctx.Int(3)])
/// ```
/// 
/// ```gleam
/// ctx.from([
///   42 |> dynamic.from,
///   3.14 |> dynamic.from,
///   "Hello" |> dynamic.from,
/// ])
/// // -> ctx.List([ctx.Int(42), ctx.Float(3.14), ctx.Str("Hello")])
/// ```
pub fn from(value: a) -> Value {
  from_dynamic(value |> dynamic.from)
}

fn from_dynamic(value: dynamic.Dynamic) -> Value {
  case value |> dynamic.classify {
    "String" -> {
      let assert Ok(val) = value |> dynamic.string
      Str(val)
    }
    "Int" -> {
      let assert Ok(val) = value |> dynamic.int
      Int(val)
    }
    "Float" -> {
      let assert Ok(val) = value |> dynamic.float
      Float(val)
    }
    "Bool" -> {
      let assert Ok(val) = value |> dynamic.bool
      Bool(val)
    }
    "Dict" -> {
      let assert Ok(val) =
        value |> dynamic.dict(dynamic.string, dynamic.dynamic)
      from_dict(val, from_dynamic)
    }
    "List" -> {
      let assert Ok(val) = value |> dynamic.list(dynamic.dynamic)
      from_list(val, from_dynamic)
    }
    _ -> panic as "Unable to construct ctx from dynamic value"
  }
}

fn from_dict(
  source: dict.Dict(String, a),
  value_mapper: fn(a) -> Value,
) -> Value {
  source
  |> dict.to_list
  |> list.map(fn(it) { Prop(it.0, value_mapper(it.1)) })
  |> Dict
}

fn from_list(source: List(a), value_mapper: fn(a) -> Value) -> Value {
  source
  |> list.map(value_mapper)
  |> List
}
