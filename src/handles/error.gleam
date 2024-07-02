pub type TokenizerError {
  UnbalancedTag(index: Int)
  MissingPropertyPath(index: Int)
  MissingBlockArgument(index: Int)
  MissingPartialId(index: Int)
  MissingPartialArgument(index: Int)
  UnexpectedMultiplePartialArguments(index: Int)
  UnexpectedBlockArgument(index: Int)
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
