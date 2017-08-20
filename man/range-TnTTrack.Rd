% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tntTracks-compositeTrack.R
\docType{methods}
\name{range-TnTTrack}
\alias{range-TnTTrack}
\alias{range-RangeTrack-method}
\alias{range,CompositeTrack-method}
\title{Range of Tracks}
\usage{
\S4method{range}{RangeTrack}(x, ..., with.revmap = FALSE,
  ignore.strand = FALSE, na.rm = FALSE)

\S4method{range}{CompositeTrack}(x, ..., with.revmap = FALSE,
  ignore.strand = FALSE, na.rm = FALSE)
}
\arguments{
\item{x}{A TnTTrack object.}

\item{..., with.revmap, ignore.strand, na.rm}{Passed to \code{\link[GenomicRanges]{range,GenomicRanges-method}}.}
}
\description{
Range of Tracks
}