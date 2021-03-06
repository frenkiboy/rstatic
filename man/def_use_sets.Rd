% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/def_use_sets.R
\name{def_use_sets}
\alias{def_use_sets}
\title{Compute Symbol Definition and Use Sets}
\usage{
def_use_sets(node, ...)
}
\arguments{
\item{node}{(ASTNode) The code object.}

\item{...}{Further arguments passed to or from other methods.}

\item{by_block}{(logical) When TRUE, the sets are computed for each Block.
When FALSE, the sets are computed for each line in each block.}
}
\value{
A two-element list. The first element contains the def sets and the
second element contains the use sets.
}
\description{
This function computes the symbol definition and use sets for a code object.
}
