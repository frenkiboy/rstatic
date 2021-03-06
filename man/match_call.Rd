% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/match_call.R
\name{match_call}
\alias{match_call}
\alias{match_call.call}
\alias{match_call.Call}
\title{Match Call Arguments to Parameters}
\usage{
match_call(node, definition, expand_dots, envir)

\method{match_call}{call}(node, definition = find_function(node, envir),
  expand_dots = TRUE, envir = parent.frame())

\method{match_call}{Call}(node, definition = find_function(node, envir),
  expand_dots = TRUE, envir = parent.frame())
}
\arguments{
\item{node}{An unevaluated call with arguments to match.}

\item{definition}{Optional definition for the called function.}

\item{expand_dots}{(logical) Should arguments matching \code{...} in the call be
expanded or left as a \code{...} argument?}

\item{envir}{(environment) An environment where \code{\link[=find_function]{find_function()}} can look
up function definition. Only used if \code{definition} is missing.}
}
\value{
An object of the same class as \code{node}, with full parameter names for
all arguments.
}
\description{
This function matches the arguments in an unevaluated call to the parameters
in a function definition.
}
\details{
This function is a wrapper for \code{\link[=match.call]{match.call()}} that adds support for:
\itemize{
\item Primitive functions
\item Anonymous functions
\item Automatic definition lookup based on the call
\item \code{ASTNode} objects as the call or the defintion
}
}
\seealso{
\code{\link[=match.call]{match.call()}}, \code{\link[=find_function]{find_function()}}
}
