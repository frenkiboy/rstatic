% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/to_ast.R
\name{quote_ast}
\alias{quote_ast}
\title{Convert Unquoted R Code to ASTNodes}
\usage{
quote_ast(expr)
}
\arguments{
\item{expr}{Unquoted R code to be converted.}
}
\description{
This function uses non-standard evaluation to convert unquoted R code to a
tree of ASTNode objects.
}
