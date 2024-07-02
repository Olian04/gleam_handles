pub type TokenizerError {
  UnbalancedTag(index: Int)
  MissingArgument(index: Int)
  MissingBlockKind(index: Int)
  MissingPartialId(index: Int)
  UnexpectedMultipleArguments(index: Int)
  UnexpectedArgument(index: Int)
  UnexpectedBlockKind(index: Int)
}

pub type RuntimeError {
  UnexpectedType(
    index: Int,
    path: List(String),
    got: String,
    expected: List(String),
  )
  UnknownProperty(index: Int, path: List(String))
  UnknownPartial(index: Int, id: String)
}
