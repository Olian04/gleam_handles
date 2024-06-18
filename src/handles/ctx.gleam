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
