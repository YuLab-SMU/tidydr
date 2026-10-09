##' Compare several dimensionality reduction methods
##'
##' `dr_compare()` applies several dimensionality reduction (DR) methods to the
##' same input data and collects their results, so that the methods can be
##' compared side by side. Every method is evaluated independently: a method that
##' fails, or that returns fewer dimensions than requested, does not interrupt
##' the others. The outcome of every method is reported in the `summary`
##' component, which is the main purpose of this function.
##'
##' A method that fails is never given placeholder coordinates. The failure is
##' recorded in `summary$error`, and the corresponding element of `results` is
##' the condition (error) object, so it can be inspected further.
##'
##' @title dr_compare
##' @param data input data. It follows the same contract as [dr()]: a numeric
##' matrix, a numeric data.frame, or a 'dist' object.
##' @param funs a named list of methods to compare. Each element is either a
##' function, or a list with components `fun` (the function) and `args` (an
##' optional list of method-specific arguments). The names are used as the method
##' labels in `summary` and in the plot, so they must be unique.
##' @param dim the two dimensions to extract, as a numeric vector of length 2.
##' Defaults to `1:2`, i.e. the first two dimensions.
##' @param metadata optional sample-level metadata. It is forwarded to
##' [fortify()] when the long table used by `autoplot()` is built, so that it
##' becomes available as a column of the plot.
##' @param ... additional arguments passed to every method in `funs`. Arguments
##' supplied through the `args` element of a method take precedence over `...`
##' for that method.
##' @return A `DrCompare` object, a list with the following components:
##' \describe{
##'   \item{`results`}{a named list with one element per method. For a method that
##'     ran successfully it is a `DrResult` (see [dr()]); for a method that failed
##'     it is the condition (error) object.}
##'   \item{`summary`}{a `data.frame` with one row per method and the columns
##'     `method`, `status`, `n`, `k`, `has_eigenvalue`, `has_stress` and `error`.
##'     `status` is `"ok"` if the method ran and returned at least `max(dim)`
##'     dimensions, `"insufficient_dims"` if it ran but returned too few
##'     dimensions, and `"failed"` if it raised an error. `n` and `k` are the
##'     number of samples and the number of extracted dimensions,
##'     `has_eigenvalue` and `has_stress` indicate whether the method produced
##'     those quantities, and `error` holds the error message of a failed method
##'     (`NA` otherwise).}
##'   \item{`dim`, `metadata`, `funs`}{the corresponding inputs, kept so that
##'     `autoplot()` can rebuild the plot.}
##' }
##' @seealso [dr()], [available_methods()]
##' @examples
##' x <- dr_compare(iris[, 1:4], list(pca = stats::prcomp))
##' x$summary
##' autoplot(x)
##' @export
##' @author Guangchuang Yu
dr_compare <- function(data, funs = list(prcomp = stats::prcomp),
                       dim = 1:2, metadata = NULL, ...) {
    ## 'data' has exactly the same contract as in `dr()`; validate it once so
    ## that an invalid input fails fast instead of failing once per method.
    validate_dr_data(data)
    funs <- check_dr_compare_funs(funs)
    dim <- check_dr_compare_dim(dim)

    n <- length(funs)
    results <- vector("list", n)
    names(results) <- names(funs)

    status <- character(n)
    n_obs <- rep(NA_integer_, n)
    n_dim <- rep(NA_integer_, n)
    has_eigenvalue <- rep(NA, n)
    has_stress <- rep(NA, n)
    error <- rep(NA_character_, n)

    for (i in seq_len(n)) {
        spec <- funs[[i]]
        ## method-specific 'args' override the global '...'
        args <- utils::modifyList(list(...), spec$args)
        res <- tryCatch(
            do.call(dr, c(list(data = data, fun = spec$fun), args)),
            error = function(e) e
        )
        results[[i]] <- res

        if (inherits(res, "error")) {
            status[i] <- "failed"
            error[i] <- conditionMessage(res)
            next
        }

        n_obs[i] <- nrow(res$drdata)
        n_dim[i] <- ncol(res$drdata)
        has_eigenvalue[i] <- !is.null(res$eigenvalue)
        has_stress[i] <- !is.null(res$stress)

        if (max(dim) > n_dim[i]) {
            status[i] <- "insufficient_dims"
            error[i] <- sprintf(
                "method returned %d dimension(s), but dim = %s requires at least %d",
                n_dim[i], paste(dim, collapse = ", "), max(dim))
        } else {
            status[i] <- "ok"
        }
    }

    summary <- data.frame(
        method = names(funs),
        status = status,
        n = n_obs,
        k = n_dim,
        has_eigenvalue = has_eigenvalue,
        has_stress = has_stress,
        error = error,
        stringsAsFactors = FALSE
    )

    structure(
        list(results = results,
             summary = summary,
             dim = dim,
             metadata = metadata,
             funs = funs),
        class = "DrCompare"
    )
}

## Validate and normalise the `funs` argument of `dr_compare()`.
## Every entry is turned into `list(fun = <function>, args = <list>)` so that the
## main loop does not need to care about the two accepted spellings.
check_dr_compare_funs <- function(funs) {
    if (!is.list(funs) || length(funs) == 0L) {
        stop("`dr_compare()`: 'funs' must be a non-empty list of functions, ",
             "e.g. `list(pca = stats::prcomp)`.", call. = FALSE)
    }

    nm <- names(funs)
    if (is.null(nm) || any(!nzchar(nm))) {
        stop("`dr_compare()`: every element of 'funs' must be named, ",
             "e.g. `list(pca = stats::prcomp, umap = uwot::umap)`.",
             call. = FALSE)
    }
    if (anyDuplicated(nm)) {
        stop("`dr_compare()`: names of 'funs' must be unique; duplicated: ",
             paste(unique(nm[duplicated(nm)]), collapse = ", "), ".",
             call. = FALSE)
    }

    lapply(funs, function(spec) {
        if (is.function(spec)) {
            return(list(fun = spec, args = list()))
        }
        if (is.list(spec) && is.function(spec[["fun"]])) {
            args <- spec[["args"]]
            if (is.null(args)) {
                args <- list()
            } else if (!is.list(args)) {
                stop("`dr_compare()`: the 'args' of a method must be a list.",
                     call. = FALSE)
            }
            return(list(fun = spec[["fun"]], args = args))
        }
        stop("`dr_compare()`: each element of 'funs' must be a function, or a ",
             "list with a 'fun' function and an optional 'args' list.",
             call. = FALSE)
    })
}

## Validate the `dim` argument of `dr_compare()`.
check_dr_compare_dim <- function(dim) {
    if (!is.numeric(dim) || length(dim) != 2L) {
        stop("`dr_compare()`: 'dim' must be a numeric vector of length 2, ",
             "e.g. `1:2`.", call. = FALSE)
    }
    if (anyNA(dim) || !all(is.finite(dim)) ||
        any(dim < 1) || any(dim != round(dim))) {
        stop("`dr_compare()`: 'dim' must be two positive integers, e.g. `1:2`.",
             call. = FALSE)
    }
    if (dim[1L] == dim[2L]) {
        stop("`dr_compare()`: 'dim' must contain two distinct dimensions.",
             call. = FALSE)
    }
    as.integer(dim)
}

## Long table (Dim1, Dim2, method, and any metadata columns) of the methods that
## can be plotted, i.e. those with status "ok". Returns NULL when there is none.
dr_compare_long <- function(x) {
    keep <- x$summary$status == "ok"
    if (!any(keep)) return(NULL)

    dim <- x$dim
    pieces <- lapply(x$summary$method[keep], function(m) {
        res <- x$results[[m]]
        f <- fortify(res, metadata = x$metadata)
        d <- as.data.frame(f[, dim, drop = FALSE])
        colnames(d) <- c("Dim1", "Dim2")
        extra_cols <- setdiff(colnames(f), colnames(res$drdata))
        if (length(extra_cols) > 0L) {
            d <- cbind(d, f[, extra_cols, drop = FALSE])
        }
        d$method <- m
        rownames(d) <- NULL
        d
    })
    do.call(rbind, pieces)
}

##' @importFrom ggplot2 facet_wrap
##' @method autoplot DrCompare
##' @export
autoplot.DrCompare <- function(object, mapping = NULL, ...) {
    Dim1 <- Dim2 <- method <- NULL

    long <- dr_compare_long(object)
    if (is.null(long)) {
        stop("`autoplot()`: none of the methods in this 'DrCompare' object ",
             "produced plottable results; see `x$summary` for the reason.",
             call. = FALSE)
    }

    if (is.null(mapping)) {
        mapping <- aes(x = Dim1, y = Dim2)
    } else {
        mapping <- modifyList(aes(x = Dim1, y = Dim2), mapping)
    }

    ggplot(long, mapping) +
        geom_point(...) +
        facet_wrap(~method, scales = "free")
}

##' @method print DrCompare
##' @export
print.DrCompare <- function(x, ...) {
    cat(sprintf("Comparison of %d dimensionality reduction method(s):\n",
                length(x$results)))
    print(x$summary, row.names = FALSE, ...)
    invisible(x)
}
