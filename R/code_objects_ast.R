# Factory function to create bindings.
binding_factory = function(field, container = FALSE) {
  binding = function(value) {}

  # Substitute the field name into the function since the function's
  # environment will be reset by R6.
  if (container) {
    body(binding) = substitute({
      if (missing(value))
        return (self$field)

      if (!is.list(value))
        value = list(value)

      self$field = set_parent(value, self)
    }, list(field = field))

  } else {
    body(binding) = substitute({
      if (missing(value))
        return (self$field)

      self$field = set_parent(value, self)
    }, list(field = field))
  }

  binding
}


ASTNode = R6::R6Class("ASTNode",
  "private" = list(
    deep_clone = function(name, value) {
      # Cloning a parent node causes an infinite cloning loop.
      # Instead, set NULL here and rely on copy() to set the parent field AFTER
      # the object has been cloned.
      if (name == "parent")
        NULL
      else
        copy(value)
    }
  ),

  "public" = list(
    parent = NULL,
    .data = list(),

    initialize = function(parent = NULL) {
      self$parent = parent
    },

    copy = function() {
      .Deprecated("copy", msg = "Use 'copy(x)' instead of 'x$copy()'.")
      copy(self)
    }
  )
)


# Containers ----------------------------------------

Container = R6::R6Class("Container", inherit = ASTNode,
  "public" = list(
    .contents = NULL,

    initialize = function(..., parent = NULL) {
      super$initialize(parent = parent)

      if (...length() == 1 && is(..1, "list"))
        contents = ..1
      else
        contents = list(...)

      self$contents = lapply(contents, to_ast)
    }
  ),

  "active" = list(
    contents = binding_factory(".contents", container = TRUE)
  )
)

#' @export
Brace = R6::R6Class("Brace", inherit = Container,
  "public" = list(
    is_hidden = FALSE,

    initialize = function(..., is_hidden = FALSE, parent = NULL)
    {
      super$initialize(..., parent = parent)

      self$is_hidden = is_hidden
    }
  )
)

#' @export
ArgumentList = R6::R6Class("ArgumentList", inherit = Container,
  "public" = list(
    initialize = function(..., parent = NULL) {
      super$initialize(parent = parent)

      # Can't use `list(...)` because some arguments may be empty.
      contents = list_dots_safely(...)

      self$contents = lapply(contents, to_ast)
    }
  )
)


#' @export
ParameterList = R6::R6Class("ParameterList", inherit = Container,
  "public" = list(
    initialize = function(..., parent = NULL) {
      super$initialize(parent = parent)

      # Can't use `list(...)` because some arguments may be empty.
      contents = list_dots_safely(...)

      self$contents = to_ast_parameters(contents)
    }
  )
)


# Control Flow ----------------------------------------

ControlFlow = R6::R6Class("ControlFlow", inherit = ASTNode)

#' @export
Branch = R6::R6Class("Branch", inherit = ControlFlow,
  "public" = list(
    target = NULL,

    initialize = function(target = Label$new(), parent = NULL) {
      super$initialize(parent)

      self$target = target
    }
  )
)

#' @export
Next = R6::R6Class("Next", inherit = Branch)

#' @export
Break = R6::R6Class("Break", inherit = Branch)

#' @export
Return = R6::R6Class("Return", inherit = Branch,
  # NOTE: We model Return as an assignment to the special variable `._return_`
  # followed by a branch to the exit block.
  "public" = list(
    .write = NULL,
    .read = NULL,

    initialize = function(args, parent = NULL) {
      super$initialize(parent = parent)

      self$write = Symbol$new("._return_")
      self$read = args
    }
  ),

  "active" = list(
    write = binding_factory(".write"),
    read  = binding_factory(".read")
  )
)


ConditionalBranch = R6::R6Class("ConditionalBranch", inherit = ControlFlow,
  "public" = list(
    .body = NULL,
    .exit = NULL,

    initialize = function(body, exit = Label$new(), parent = NULL) {
      super$initialize(parent = parent)

      self$body = body
      self$exit = exit
    }
  ),

  "active" = list(
    body = binding_factory(".body"),
    exit = binding_factory(".exit")
  )
)

#' @export
If = R6::R6Class("If", inherit = ConditionalBranch,
  "public" = list(
    .condition = NULL,

    initialize = function(condition, true, false = Brace$new(),
      parent = NULL)
    {
      super$initialize(body = true, exit = false, parent = parent)

      self$condition = condition
    }
  ),

  "active" = list(
    condition = binding_factory(".condition"),
    # Keep old true/false bindings for interactive use.
    true      = binding_factory(".body"),
    false     = binding_factory(".exit")
  )
)


Loop = R6::R6Class("Loop", inherit = ConditionalBranch)

#' @export
For = R6::R6Class("For", inherit = Loop,
  "public" = list(
    .variable = NULL,
    .iterator = NULL,

    initialize = function(variable, iterator, body, parent = NULL) {
      super$initialize(body = body, parent = parent)

      self$variable = variable
      self$iterator = iterator
    }
  ),

  "active" = list(
    variable = binding_factory(".variable"),
    iterator = binding_factory(".iterator")
  )
)

#' @export
While = R6::R6Class("While", inherit = Loop,
  "public" = list(
    .condition = NULL,
    is_repeat = FALSE,

    initialize = function(condition, body, is_repeat = FALSE, parent = NULL) {
      super$initialize(body = body, parent = parent)

      self$condition = condition
      self$is_repeat = is_repeat
    }
  ),

  "active" = list(
    condition = binding_factory(".condition")
  )
)


# Calls ----------------------------------------

Invocation = R6::R6Class("Invocation", inherit = ASTNode,
  "public" = list(
    .args = NULL,

    initialize = function(..., parent = NULL) {
      super$initialize(parent = parent)

      if (...length() == 1 && is(..1, "ArgumentList"))
        self$args = ..1
      else
        self$args = ArgumentList$new(...)
    }
  ),

  "active" = list(
    args = binding_factory(".args")
  )
)

#' @export
Call = R6::R6Class("Call", inherit = Invocation,
  "public" = list(
    .fn = NULL,

    initialize = function(fn, ..., parent = NULL) {
      super$initialize(..., parent = parent)

      # NOTE: fn could be a Symbol, Function, Primitive, or Call.
      if (!is(fn, "ASTNode"))
        fn = Symbol$new(fn)

      self$fn = fn
    }
  ),

  "active" = list(
    fn = binding_factory(".fn")
  )
)

#' @export
Internal = R6::R6Class("Internal", inherit = Call,
  "public" = list(
    initialize = function(args = NULL, parent = NULL) {
      super$initialize(fn = ".Internal", args = args, parent = parent)
    }
  )
)

#' @export
Parenthesis = R6::R6Class("Parenthesis", inherit = Invocation)

#' @export
Namespace = R6::R6Class("Namespace", inherit = Call)

#' @export
Subset = R6::R6Class("Subset", inherit = Call)

#' @export
Subset1 = R6::R6Class("Subset1", inherit = Subset)

#' @export
Subset2 = R6::R6Class("Subset2", inherit = Subset)

#' @export
SubsetDollar = R6::R6Class("SubsetDollar", inherit = Subset)


# Assignment
# --------------------
#' @export
Assignment = R6::R6Class("Assignment", inherit = ASTNode,
  "public" = list(
    .write = NULL,
    .read = NULL,

    initialize = function(write, read, parent = NULL) {
      super$initialize(parent)

      self$write = to_ast(write)
      self$read = to_ast(read)
    }
  ),

  "active" = list(
    write = binding_factory(".write"),
    read  = binding_factory(".read")
  )
)

#' @export
SuperAssignment = R6::R6Class("SuperAssignment", inherit = Assignment)

#' @export
Replacement = R6::R6Class("Replacement", inherit = Assignment)

#' @export
Replacement1 = R6::R6Class("Replacement1", inherit = Replacement)

#' @export
Replacement2 = R6::R6Class("Replacement2", inherit = Replacement)

#' @export
ReplacementDollar = R6::R6Class("ReplacementDollar", inherit = Replacement)


# Symbols ----------------------------------------

#' @export
Symbol = R6::R6Class("Symbol", inherit = ASTNode,
  "public" = list(
    value = NULL,
    ssa_number = NULL,
    namespace = NULL,
    namespace_fn = NULL,

    initialize = function(
      value, ssa_number = NA_integer_,
      namespace = NA_character_, namespace_fn = NULL,
      parent = NULL
    ) {
      if ( !(is.character(value) || is.symbol(value)) )
        stop("Symbol value must be a character or a name.", call. = FALSE)

      super$initialize(parent)
      self$value = as.character(value)
      self$ssa_number = ssa_number

      self$namespace = namespace
      self$namespace_fn = namespace_fn
    }
  ),

  "active" = list(
    ssa_name = function() {
      ssa_number = self$ssa_number
      if (is.na(ssa_number))
        return (self$value)

      sprintf("%s_%i", self$value, ssa_number)
    }
  )
)

#' @export
Parameter = R6::R6Class("Parameter", inherit = Symbol,
  "public" = list(
    .default = NULL,

    # FIXME: Maybe default should be 3rd argument.
    initialize = function(value
      , default = EmptyArgument$new()
      , ssa_number = NA_integer_
      , parent = NULL)
    {
      super$initialize(value = value, ssa_number = ssa_number, parent = parent)

      self$default = default
    }
  ),

  "active" = list(
    default = binding_factory(".default")
  )
)


# Functions
# --------------------

Callable = R6::R6Class("Callable", inherit = ASTNode,
  "public" = list(
    .params = NULL,

    initialize = function(..., parent = NULL) {
      super$initialize(parent = parent)

      if (...length() == 1 && is(..1, "ParameterList"))
        self$params = ..1
      else
        self$params = ParameterList$new(...)
    }
  ),

  "active" = list(
    params = binding_factory(".params")
  )
)

#' @export
Function = R6::R6Class("Function", inherit = Callable,
  "public" = list(
    .body = NULL,

    initialize = function(body, ..., parent = NULL) {
      super$initialize(..., parent = parent)

      self$body = body
    }
  ),

  "active" = list(
    body = binding_factory(".body")
  )
)

#' @export
Primitive = R6::R6Class("Primitive", inherit = Callable,
  "public" = list(
    .fn = NULL,

    initialize = function(fn, ..., parent = NULL) {
      super$initialize(..., parent = parent)

      if (!is(fn, "Symbol"))
        fn = Symbol$new(fn)

      self$fn = fn
    }
  ),

  "active" = list(
    fn = binding_factory(".fn")
  )
)

# Literals ----------------------------------------

Literal = R6::R6Class("Literal", inherit = ASTNode,
  "public" = list(
    value = NULL,

    initialize = function(value, parent = NULL) {
      super$initialize(parent)
      self$value = value
    }
  )
)

#' @export
EmptyArgument = R6::R6Class("EmptyArgument", inherit = Literal,
  "public" = list(
    initialize = function(parent = NULL) {
      super$initialize(quote(expr = ), parent = parent)
    }
  )
)

#' @export
Null = R6::R6Class("Null", inherit = Literal,
  "public" = list(
    initialize = function(parent = NULL) {
      super$initialize(NULL, parent)
    }
  )
)

#' @export
Logical = R6::R6Class("Logical", inherit = Literal)

#' @export
Integer = R6::R6Class("Integer", inherit = Literal)

#' @export
Numeric = R6::R6Class("Numeric", inherit = Literal)

#' @export
Complex = R6::R6Class("Complex", inherit = Literal)

#' @export
Character = R6::R6Class("Character", inherit = Literal)
