pub type TokenizerError {
  UnbalancedTag(index: Int)
  MissingPropertyPath(index: Int)
  MissingBlockArgument(index: Int)
  UnexpectedBlockArgument(index: Int)
  UnexpectedBlockKind(index: Int)
}

pub type RuntimeError {
  UnexpectedTypeError(
    index: Int,
    path: List(String),
    got: String,
    expected: List(String),
  )
  UnknownPropertyError(index: Int, path: List(String))
}
