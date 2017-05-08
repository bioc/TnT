
### "JavaScript" is a class to represent literal javascript code.
###
### "JSCascade" is a class used to model a javascript function cascade.
### It can be created with the function "jc" and possibly "ma", then can be
### converted to "JavaScript" with "asJS".
###
### The following is an example of using JSCascade to construct a TnT browser

### EXAMPLE
if (interactive()) local({
    axisTrack <- jc(
        tnt.board.track = ma(),
        height = 20,
        color = "white",
        display = jc(tnt.board.track.feature.axis = ma())
    )
    blockTrack <- jc(
        tnt.board.track = ma(),
        height = 30,
        color = "yellow",
        data = jc(
            tnt.board.track.data.sync = ma(),
            retriever = js("function() {return [{start : 200, end : 350}]}")
        ),
        display = jc(
            tnt.board.track.feature.block = ma(),
            color = "blue",
            index = js("function (d) {return d.start}")
        )
    )
    tntdef <- jc(
        tnt.board = ma(),
        from = 0,
        to = 500,
        min = 50,
        max = 1000,
        width = 500,
        add_track = axisTrack,
        add_track = blockTrack
    )
    tntdef
    asJS(tntdef)
    TnT(tntdef)
})
### EXAMPLE END




## Classes and Generics     ----------------------------------------------------

setClass("JavaScript", contains = "character")
setClass("JSCascade", contains = "SimpleList")
setClass("MultiArgs", contains = "SimpleList")

#' @export
JavaScript <- function (code) {
    new("JavaScript", code)
}

#' @export
JSCascade <- function (..., .listData) {
    if (missing(.listData))
        lst <- list(...)
    else
        lst <- .listData
    
    # If the element is NULL, then drop the element from the list
    todrop <- vapply(lst, is.null, logical(1))
    ans <- new("JSCascade", listData = lst[!todrop])
    ans
}

#' @export
MultiArgs <- function (..., .listData) {
    if (missing(.listData))
        new("MultiArgs", listData = list(...))
    else
        new("MultiArgs", listData = .listData)
}

#' @export
NoArg <- MultiArgs()

#' @export
js <- JavaScript
#' @export
jc <- JSCascade
#' @export
ma <- MultiArgs
#' @export
na <- NoArg


#' @export
setGeneric("asJS",
    function (object) standardGeneric("asJS")
)

#' @export
setGeneric("asJC",
    function (object, ...) standardGeneric("asJC")
)



## Validity                 ----------------------------------------------------

# TODO:
#   Check whether the numeric/character/logical vectors in JC and MA are of length 1,
#   then update the unit test.

setValidity("JSCascade",
    function (object) {
        lst <- as.list(object)
      # Ensure there is no "NULL" value
        isnull <- vapply(lst, is.null, logical(1))
        if (any(isnull))
            return("NULL is not allowed in JSCascade")
      # Ensure the names are specified
        if (is.null(names(lst)) || any(names(lst) == ""))
            return("Names must be specified.")
      # Only allow certain types of element
        isAllowed <- vapply(lst, inherits, FUN.VALUE = logical(1),
            what = c("JSCascade", "MultiArgs", "JavaScript",
                     "integer", "numeric", "logical", "character")
        )
        if (!all(isAllowed)) {
            classes <- vapply(lst[!isAllowed], FUN.VALUE = character(1),
                function (element) class(element)[1]
            )
            classes <- unique(classes)
            return(paste("Class", classes, "is not allowed."))
        }
        
        TRUE
    }
)

setValidity("MultiArgs",
    function (object) {
        lst <- as.list(object)
      # Only allow position-based JS call
        if (!is.null(names(lst)) && any(names(lst) != ""))
            message("The names will be ignored at present.")
      # Only allow certain types of element
        isAllowed <- vapply(lst, inherits, FUN.VALUE = logical(1),
            what = c("JSCascade", "JavaScript",
                     "integer", "numeric", "logical", "character")
        )
        if (!all(isAllowed)) {
            classes <- vapply(lst[!isAllowed], FUN.VALUE = character(1),
                function (element) class(element)[1]
            )
            classes <- unique(classes)
            return(paste("Class", classes, "is not allowed."))
        }
        
        TRUE
    }
)


## Methods    ------------------------------------------------------------------

setMethod("asJS", signature = "JSCascade",
    function (object) {
        chr <- .convertToJSChar(jc = object)
        JavaScript(chr)
    }
)

setMethod("asJC", signature = c(object = "list"),
    function (object, ...) {
        stopifnot(length(list(...)) == 0) # There should no extra argument for this method
        JSCascade(.listData = object)
    }
)



.convertToJSChar <- function (jc) {
    .local.JSCascade <- function (el) {
        jscalls <- names(el)
        jsargs <- vapply(el, .local, character(1))
        each <- sprintf("%s(%s)", jscalls, jsargs)
        paste(each, collapse = "\n.")
    }
    .local.MultiArgs <- function (el) {
        if (length(el) == 1)
            .local(el)
        else {
            l <- vapply(el, FUN = .local, FUN.VALUE = character(1))
            paste(l, collapse = ", ")
        }
    }
    .local.numeric <- function (el) {
        as.character(el)      # TODO: Should also consider NA, NaN and Inf
    }
    .local.logical <- function (el) {
        if (is.na(el)) stop() # TODO: use "none"?
        else if (el) "true"
        else if (!el) "false"
        else stop()
    }
    .local.JavaScript <- function (el) {
        as.character(el)
    }
    .local.character <- function (el) {
        # To add quotation marks to the string and substitute existing “'” with “\'”.
        # A revelent function is "shQuote()"
        s <- gsub("'", "\\'", el, fixed = TRUE)
        sprintf("'%s'", s)
    }
    
    .local <- function (el) {
        if (inherits(el, "JSCascade"))  return(.local.JSCascade(el))
        if (inherits(el, "MultiArgs"))  return(.local.MultiArgs(el))
        if (inherits(el, "JavaScript")) return(.local.JavaScript(el))
        if (is.numeric(el))             return(.local.numeric(el)) # also works for integer
        if (is.logical(el))             return(.local.logical(el))
        if (is.character(el))           return(.local.character(el))
        stop()
    }
    .local(jc)
}











## Show-methods    -------------------------------------------------------------

setMethod("show", signature = "JSCascade",
    function (object) {
        cat("JSCascade Object:\n------\n")
        js <- asJS(object)
        show(js)
        invisible(object)
    }
)


setMethod("show", signature = "JavaScript",
    # Print the javascript code with indentation
    
    function (object) {
        byline <- strsplit(object, "\n", fixed = TRUE)[[1]]
        l_par_cum <- cumsum(lengths(regmatches(byline, gregexpr("(", byline, fixed = TRUE))))
        r_par_cum <- cumsum(lengths(regmatches(byline, gregexpr(")", byline, fixed = TRUE))))
        indent <- l_par_cum - r_par_cum
        spaces <- sapply(indent, FUN = function (n) {
            paste(rep("  ", n), collapse = "")
        })
        out <- paste0(byline, "\n", spaces)
        cat(out)
        invisible(object)
    }
)
