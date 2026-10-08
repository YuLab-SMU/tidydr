##' Choose best K (number of clusters)
##' 
##' This function calculate the silhouette scores of each K (number of clusters). 
##' The output object can be used to choose the best K (via `summary()` or `autoplot()` methods)
##' @title nk
##' @param data input data (a matrix, data frame, or 'dist' object)
##' @param k a vector of candidate number of clusters
##'
##' Note: this function calls `cluster::pam()` once for each candidate k, and `pam()` has O(n^2) time and memory complexity in the number of samples. For large datasets (e.g., thousands of cells/samples), this can be slow or memory-intensive. Consider subsampling the data or reducing the range of k for exploratory use.
##' @return a `silinfo` object, which contains 'data' (original data), 'silinfo' (silhouette scores), and k (the input k vector)
##' @importFrom cluster pam
##' @export
##' @examples
##' x <- nk(iris[,-5], 2:8)
##' summary(x)
##' # to visualize the average silhouete score (y axis) with k (x axis)
##' autoplot(x)
##' # to visualize a PCA plot color by the choosing k
##' autoplot(x, k=3)
##' @author Guangchuang Yu
nk <- function(data, k) {
    n <- validate_nk_data(data)
    if (missing(k)) {
        stop("`nk()`: 'k' must be provided (a vector of candidate numbers of clusters).",
             call. = FALSE)
    }
    validate_nk_k(k, n = n)

    y = lapply(k, function(i) {
        x <- pam(data, k=i)
        x$silinfo
    })
    structure(list(data = data,
                silinfo = y, 
                k=k),
        class = "silinfo"
    )
}

## Internal input contract checks for `nk()`.
## Deliberately self-contained (no shared helper with `dr()`): keeping the two
## units decoupled means each can be changed and verified on its own.
##
## Returns (invisibly) the number of observations.  `cluster::pam()` also
## accepts dissimilarities, so `dist` objects are supported here as well; note
## that `is.vector(as.dist(x))` and `is.matrix(as.dist(x))` are both FALSE, so
## they must be recognised explicitly (via `inherits()`).
validate_nk_data <- function(data) {
    if (is.null(data)) {
        stop("`nk()`: 'data' must not be NULL. ",
             "Please supply a numeric matrix or data.frame.", call. = FALSE)
    }

    if (inherits(data, "dist")) {
        if (anyNA(data) || !all(is.finite(data))) {
            stop("`nk()`: 'data' contains missing (NA/NaN) or infinite (Inf) values. ",
                 "Please handle missing values (e.g. impute or drop them) ",
                 "before calling `nk()`.", call. = FALSE)
        }
        n <- attr(data, "Size")
        if (is.null(n)) {
            n <- as.integer((1 + sqrt(1 + 8 * length(data))) / 2)
        }
        if (n < 2) {
            stop("`nk()`: 'data' must have at least 2 observations.", call. = FALSE)
        }
        return(invisible(n))
    }

    if (is.data.frame(data)) {
        if (ncol(data) < 1) {
            stop("`nk()`: 'data' must have at least one column.", call. = FALSE)
        }
        num <- vapply(data, is.numeric, logical(1))
        if (!all(num)) {
            stop("`nk()`: all columns of 'data' must be numeric. ",
                 "Non-numeric column(s): ", paste(names(data)[!num], collapse = ", "), ".",
                 call. = FALSE)
        }
        ok <- vapply(data, function(x) !anyNA(x) && all(is.finite(x)), logical(1))
        bad <- !all(ok)
    } else if (is.matrix(data)) {
        if (!is.numeric(data)) {
            stop("`nk()`: 'data' must be a numeric matrix, but a matrix of mode '",
                 mode(data), "' was supplied.", call. = FALSE)
        }
        if (ncol(data) < 1) {
            stop("`nk()`: 'data' must have at least one column.", call. = FALSE)
        }
        bad <- anyNA(data) || !all(is.finite(data))
    } else {
        stop("`nk()`: 'data' must be a numeric matrix, data.frame or 'dist' object, not ",
             paste(class(data), collapse = "/"), ".", call. = FALSE)
    }

    if (bad) {
        stop("`nk()`: 'data' contains missing (NA/NaN) or infinite (Inf) values. ",
             "Please handle missing values (e.g. impute or drop them) ",
             "before calling `nk()`.", call. = FALSE)
    }

    if (nrow(data) < 2) {
        stop("`nk()`: 'data' must have at least 2 rows (samples).", call. = FALSE)
    }

    invisible(nrow(data))
}

## `cluster::pam()` accepts k = 1, but the silhouette width is undefined for a
## single cluster (`silinfo$avg.width` is NULL), which used to yield an object
## that could not be printed.  Fail fast here instead.
validate_nk_k <- function(k, n) {
    if (is.null(k)) {
        stop("`nk()`: 'k' must be provided (a vector of candidate numbers of clusters).",
             call. = FALSE)
    }
    if (!is.numeric(k)) {
        stop("`nk()`: 'k' must be a numeric vector, not ", class(k)[1], ".",
             call. = FALSE)
    }
    if (anyNA(k) || !all(is.finite(k))) {
        stop("`nk()`: 'k' must not contain NA/NaN/Inf.", call. = FALSE)
    }
    if (any(k != round(k))) {
        stop("`nk()`: 'k' must be integers, got ", paste(k[k != round(k)], collapse = ", "), ".",
             call. = FALSE)
    }
    if (any(k < 2)) {
        stop("`nk()`: 'k' must be at least 2; the silhouette width is undefined for k = 1.",
             call. = FALSE)
    }
    if (any(k >= n)) {
        stop(sprintf("`nk()`: 'k' must be smaller than the number of samples (n = %d), got k = %s.",
                     n, paste(k[k >= n], collapse = ", ")), call. = FALSE)
    }
    invisible(TRUE)
}

##' @method print silinfo
##' @export
print.silinfo <- function(x, ...) {
    y <- summary(x)
    best <- which.max(y[,2])
    k <- y[best, 1]
    avg.width <- y[best, 2]

    msg <- c(
        sprintf("Silhouette information for K = %s", paste0(range(x$k), collapse=":")),
        sprintf("Best K (number of clusters) is %s (average silhouette width: %.3f)", k, avg.width)
        )
    if (avg.width < 0.25) {
        msg <- c(msg, "Note: the silhouette width is relatively low, suggesting the clustering structure may be weak.")
    }
    cat(msg, sep = "\n")
}

##' @method summary silinfo
##' @export
summary.silinfo <- function(object, ...) {
    K <- object$k
    y <- vapply(object$silinfo, function(x) {
            x$avg.width
        }, FUN.VALUE = numeric(1))

    res <- data.frame(K=K, 
            Silhouette = y)
    return(res)
}

