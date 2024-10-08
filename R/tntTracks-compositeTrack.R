

#' @include tntTracks-compilation.R

setClass("CompositeTrackData", contains = c("list", "TrackData"))
setClass("CompositeTrack", contains = "TnTTrack", slots = c(Data = "CompositeTrackData"))

setValidity("CompositeTrackData",
    function (object) {
        if (!all(vapply(object, is, logical(1L), class2 = "RangeBasedTrack")))
            return("All components of CompositeTrack should be RangeBasedTrack")
        return(TRUE)
    }
)

CompositeTrackData <- function (tracklist) {
    new("CompositeTrackData", tracklist)
}

#' Composite Track
#' 
#' Two or more arbitrary tracks can be used to create a composite track, by which
#' different features can be shown in the same track.
#' 
#' @name composite-track
#' @aliases merge-track  merge,TnTTrack,TnTTrack-method
#' @param x,y,... Track constructed with \link{track-constructors} or composite track.
#'
#' @return
#'     Returns a "CompositeTrack" object.
#' 
#' @seealso \url{http://tnt.marlin.pub/articles/examples/track-CompositeTrack.html}
#' @export
#' @examples
#' gr <- GRanges("chr1", IRanges(c(11000, 20000, 60000), width = 2000))
#' gpos <- GRanges("chr1", IRanges(c(12000, 21000, 61000), width = 1), value = c(1, 2, 3))
#' btrack <- BlockTrack(gr, label = "Block Track", tooltip = as.data.frame(gr), color = "lightblue4")
#' ptrack <- PinTrack(gpos, label = "Pin Track", tooltip = as.data.frame(gpos), background = "beige")
#' 
#' ctrack <- merge(btrack, ptrack)
#' \dontrun{
#' TnTBoard(ctrack)
#' }
setMethod("merge", signature = c(x = "TnTTrack", y = "TnTTrack"),
    function (x, y, ...) {
        tracklist <- list(x, y, ...)
        merge_tracklist(tracklist)
    }
)

#' @rdname composite-track
setMethod("merge", signature = c(x = "TnTTrack", y = "missing"),
    function (x, y, ...) {
        tracklist <- list(x, ...)
        merge_tracklist(tracklist)
    }
)

merge_tracklist <- function (tracklist) {
    for (i in seq_along(tracklist))
        if (!(is(tracklist[[i]], "RangeBasedTrack") || is(tracklist[[i]], "CompositeTrack")))
            stop("All tracks have to inherit either 'RangeBasedTrack' or 'CompositeTrack'")
    
    tracklist <- as.list(tracklist)
    which.comp <- vapply(tracklist, is, logical(1L), class2 = "CompositeTrack")
    tracklist[which.comp] <- lapply(tracklist[which.comp], trackData)
    tracklist <- c(tracklist, recursive = TRUE, use.names = FALSE)
    tracklist <- .consolidateSeqinfo(tracklist)
    
    .merge_tracklist <- function (tracklist) {
        spec <- .mergeSpec(tracklist)
        ans <- new("CompositeTrack", Data = CompositeTrackData(tracklist))
        trackSpec(ans, which = names(spec)) <- spec
        ans
    }
    .mergeSpec <- function (tracklist) {
        labels      <- unname(unlist(lapply(tracklist, trackSpec, which = "label")))
        heights     <- unname(unlist(lapply(tracklist, trackSpec, which = "height")))
        backgrounds <- unname(unlist(lapply(tracklist, trackSpec, which = "background")))
        
        stopifnot(is.atomic(labels) || is.null(labels),
                  is.atomic(heights) || is.null(heights),
                  is.atomic(backgrounds) || is.null(backgrounds))
        
        f <- function(x, w = c("label", "height", "background")) {
            w <- match.arg(w)
            if (!length(x))
                return(NULL)
            if (length(x) == 1L)
                return(x)
            if (w == "label")
                return(paste(paste(x[-length(x)], collapse = ", "), x[length(x)], sep = " and "))
            if (w == "height")
                return(na.fail(max(na.omit(x))))
            if (w == "background")
                return(x[1])
            stop("<internal> Unmatched argument")
        }
        list(
            label      = f(labels,      "label"),
            height     = f(heights,     "height"),
            background = f(backgrounds, "background")
        )
    }
    .merge_tracklist(tracklist)
}

.mkref <- function (l)
    paste0("subtrack", seq_along(l))

setMethod("compileTrackData", signature = "CompositeTrackData",
    function (trackData) {
        li.t <- as.list(trackData)
        
        li.retriever <- lapply(li.t,
            function (t) {
                cd <- compileTrackData(trackData(t))
                stopifnot(
                    length(cd) == 2,
                    identical(names(cd), c("tnt.board.track.data.sync", "retriever"))
                )
                cd[[2]]
            }
        )
        
        jc.retriever <- {
            jc.init <- jc(tnr.composite_data_retriever = ma())
            jc.add <- {
                li.add <- mapply(ref = .mkref(li.t), func = li.retriever,
                                 USE.NAMES = FALSE, SIMPLIFY = FALSE,
                    function (ref, func)
                        jc(add = ma(ref, func))
                )
                do.call(c, unname(li.add))
            }
            jc.end <- jc(done = ma())
            
            c(jc.init, jc.add, jc.end)
        }
        
        jc(tnt.board.track.data.sync = ma(),
           retriever = jc.retriever)
    }
)


setMethod("wakeupTrack", signature = c(track = "CompositeTrack"),
    function (track) {
        li.track  <- lapply(trackData(track), wakeupTrack)
        
        li.disply <- lapply(li.track, function (t) asJC(t@Display))
        refs <- .mkref(li.track)
        
        l.init <- list(tnt.board.track.feature.composite = ma())
        l.add <- {
            l.add <- mapply(ref = refs, jc.dis = li.disply,
                            USE.NAMES = FALSE, SIMPLIFY = FALSE,
                function (ref, jc.dis) {
                    list(add = ma(ref, jc.dis))
                }
            )
            do.call(c, unname(l.add))
        }
        
        trackData(track) <- CompositeTrackData(li.track)
        track@Display <- c(l.init, l.add)
        track
    }
)


#' @rdname seqinfo
setMethod("seqinfo", signature = "CompositeTrack",
    function (x) .mergeSeqinfo(trackData(x))
)

#' @rdname seqinfo
setReplaceMethod("seqinfo", signature = c(x = "CompositeTrack"),
    function (x, new2old, pruning.mode, value) {
        ## We need to make sure the sub-tracks have the same seqinfo, otherwise
        ## functions like `seqlevels<-` will not work correctly.
        trackData(x) <- .consolidateSeqinfo(trackData(x))
        
        li.tracks <- trackData(x)
        for (i in seq_along(li.tracks))
            seqinfo(li.tracks[[i]], new2old, pruning.mode) <- value
        trackData(x) <- li.tracks
        x
    }
)

#' @rdname seqinfo
setMethod("seqlevelsInUse", signature = c(x = "CompositeTrack"),
    function (x) {
        li.tracks <- trackData(x)
        li.seqs <- lapply(li.tracks, seqlevelsInUse)
        unique(unlist(li.seqs))
    }
)


#### range Methods          ========

.range.track <- function (x, ..., with.revmap = FALSE, ignore.strand=FALSE, na.rm=FALSE) {
    li.tracks <- list(x, ...)
    
    joingr <- function (li.gr) {
        li.gr <- lapply(unname(li.gr), granges)
        do.call(c, li.gr)
    }
    
    li.gr <- lapply(unname(li.tracks), function (track) {
        if (is(track, "RangeBasedTrack"))
            return(granges(trackData(track)))
        if (is(track, "CompositeTrack")) {
            lgr <- lapply(trackData(track), trackData)
            return(joingr(lgr))
        }
        stop(sprintf("Class %s is not supported.", class(track)))
    })
    
    inner_call <- function (...) {
        range(..., with.revmap = with.revmap, ignore.strand = ignore.strand, na.rm = na.rm)
    }
    do.call(inner_call, unname(li.gr))
}

#' Range of Tracks
#' 
#' @param x A TnTTrack object.
#' @param ...,with.revmap,ignore.strand,na.rm
#'     Passed to \code{\link[GenomicRanges]{range,GenomicRanges-method}}.
#' @aliases range,RangeBasedTrack-method
#' @return Returns a GRanges object.
#' @name range-TnTTrack
setMethod("range", signature = c(x = "RangeBasedTrack"), .range.track)

#' @rdname range-TnTTrack
setMethod("range", signature = c(x = "CompositeTrack"), .range.track)



