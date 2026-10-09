##' Choose best K (number of clusters)
##' 
##' This function calculate the silhouette scores of each K (number of clusters). 
##' The output object can be used to choose the best K (via `summary()` or `autoplot()` methods)
##' @title nk
##' @param data input data (a matrix, data frame, or 'dist' object)
##' @param k a vector of candidate number of clusters
##' @param fun a function to perform the clustering. It must accept the number of
##' clusters as its second argument, or through an argument named `k` or `centers`
##' (e.g. `cluster::pam`, `stats::kmeans`). A method that takes no cluster count
##' (e.g. `stats::hclust`) is called on the dissimilarity and cut with
##' `stats::cutree()`. `fun` must return either a vector of cluster labels of
##' length `nrow(data)`, or an object labels can be extracted from
##' (`$clustering`, `$cluster` or `$labels`). Defaults to `cluster::pam`.
##'
##' Whether `fun` is given a cluster count is decided by inspecting its arguments:
##' a `k` or `centers` argument means yes, a first argument named `d` (the
##' `stats::hclust()` convention) means no. A method that takes a dissimilarity as
##' a first argument under some other name, such as `cluster::agnes()` or
##' `cluster::diana()`, is therefore read as taking a cluster count and will fail;
##' wrap it so that `k` is an argument of its own, e.g.
##' `nk(x, 2:4, fun = function(z, k) stats::cutree(cluster::agnes(stats::dist(z)), k))`.
##' @param ... additional parameters passed to `fun`
##'
##' Note: by default this function calls `cluster::pam()` once for each candidate k, and `pam()` has O(n^2) time and memory complexity in the number of samples. For large datasets (e.g., thousands of cells/samples), this can be slow or memory-intensive. Consider subsampling the data or reducing the range of k for exploratory use.
##' @return a `silinfo` object, which contains 'data' (original data), 'silinfo' (silhouette scores), and k (the input k vector)
##' @details
##' The silhouette width is computed with `cluster::silhouette()` from the cluster
##' labels and the dissimilarity of `data` (`stats::dist(data)`, unless `data` is
##' already a 'dist' object, in which case it is used as is). With the default
##' `fun = cluster::pam` the silhouette information that `pam()` computes itself is
##' reused verbatim, so the default result is unchanged.
##'
##' Each element of `$silinfo` follows the shape produced by `cluster::pam()`:
##' `widths` (a matrix with columns `cluster`, `neighbor` and `sil_width`),
##' `clus.avg.widths` (per-cluster averages) and `avg.width` (the overall average).
##' The row order of `widths` is the one produced by the clusterer, so it should be
##' aligned by sample name rather than by position.
##' @importFrom cluster pam
##' @export
##' @examples
##' x <- nk(iris[,-5], 2:8)
##' summary(x)
##' # to visualize the average silhouete score (y axis) with k (x axis)
##' autoplot(x)
##' # to visualize a PCA plot color by the choosing k
##' autoplot(x, k=3)
##'
##' # another clustering method
##' x2 <- nk(iris[,-5], 2:4, fun = stats::kmeans)
##' summary(x2)
##' # a hierarchical method is cut automatically
##' x3 <- nk(iris[,-5], 2:4, fun = stats::hclust)
##' summary(x3)
##' @author Guangchuang Yu
nk <- function(data, k, fun = pam, ...) {
    n <- validate_nk_data(data)
    if (missing(k)) {
        stop("`nk()`: 'k' must be provided (a vector of candidate numbers of clusters).",
             call. = FALSE)
    }
    validate_nk_k(k, n = n)
    if (!is.function(fun)) {
        stop("`nk()`: 'fun' must be a function.", call. = FALSE)
    }

    ## A clusterer that takes no cluster count (e.g. stats::hclust) consumes a
    ## dissimilarity: fit it once and cut the tree for every candidate k.
    fixed <- !nk_takes_k(fun)
    fitted <- if (fixed) {
        tryCatch(fun(nk_dissimilarity(data), ...),
                 error = function(e) {
                     stop("`nk()`: clustering with 'fun' failed: ",
                          conditionMessage(e), call. = FALSE)
                 })
    } else {
        NULL
    }

    ## `d` is built at most once, and only when the generic silhouette path is
    ## really used (the pam fast path never needs it).
    d <- NULL
    diss <- function() {
        if (is.null(d)) d <<- nk_dissimilarity(data)
        d
    }

    y <- lapply(k, function(i) {
        obj <- if (fixed) {
            fitted
        } else {
            tryCatch(nk_fit(fun, data, k = i, ...),
                     error = function(e) {
                         stop(sprintf("`nk()`: clustering with 'fun' failed for k = %s: %s",
                                      i, conditionMessage(e)), call. = FALSE)
                     })
        }
        nk_silinfo(obj, k = i, n = n, diss = diss)
    })
    structure(list(data = data,
                silinfo = y, 
                k=k),
        class = "silinfo"
    )
}

## Dissimilarity of `data`: a 'dist' object is used as is.
nk_dissimilarity <- function(data) {
    if (inherits(data, "dist")) return(data)
    stats::dist(data)
}

## Does `fun` accept the number of clusters?  A method whose first argument is
## named `d` (by convention a dissimilarity, e.g. stats::hclust) does not.
nk_takes_k <- function(fun) {
    fml <- tryCatch(names(formals(fun)), error = function(e) character())
    if (length(fml) == 0L) return(TRUE)          # unknown signature: pass k along
    if ("k" %in% fml || "centers" %in% fml) return(TRUE)
    !identical(fml[1L], "d")
}

## Fit `fun` for one candidate k.
nk_fit <- function(fun, data, k, ...) {
    fml <- names(formals(fun))
    if ("k" %in% fml) return(fun(data, k = k, ...))
    if ("centers" %in% fml) return(fun(data, centers = k, ...))
    fun(data, k, ...)
}

## Extract cluster labels from whatever `fun` returned.
nk_labels <- function(obj, k, n) {
    if (inherits(obj, "hclust")) {
        labels <- stats::cutree(obj, k = k)
    } else if (is.atomic(obj) && (is.null(dim(obj)) || ncol(obj) == 1L)) {
        labels <- as.vector(obj)
    } else {
        labels <- NULL
        for (nm in c("clustering", "cluster", "labels")) {
            cand <- tryCatch(obj[[nm]], error = function(e) NULL)
            if (!is.null(cand)) {
                labels <- cand
                break
            }
        }
        if (is.null(labels)) {
            stop("`nk()`: cannot extract cluster labels from the object returned by 'fun'. ",
                 "Return a vector of labels, or an object with a 'clustering', ",
                 "'cluster' or 'labels' component.", call. = FALSE)
        }
        labels <- as.vector(labels)
    }

    if (length(labels) != n) {
        stop(sprintf("`nk()`: 'fun' returned %d cluster labels, but 'data' has %d observations.",
                     length(labels), n), call. = FALSE)
    }
    if (length(unique(labels)) < 2L) {
        stop("`nk()`: 'fun' returned a single cluster; the silhouette width is undefined ",
             "for a single cluster.", call. = FALSE)
    }
    labels
}

## Assemble the pam-shaped silhouette information for a fitted clusterer.
## For a `pam` result the information pam already computed is returned verbatim.
nk_silinfo <- function(obj, k, n, diss) {
    if (inherits(obj, "pam") && !is.null(obj$silinfo)) {
        return(obj$silinfo)
    }
    labels <- nk_labels(obj, k = k, n = n)
    s <- cluster::silhouette(labels, diss())
    w <- as.matrix(s)
    if (is.null(rownames(w))) {
        rownames(w) <- as.character(seq_len(nrow(w)))
    }
    list(widths = w,
         clus.avg.widths = as.numeric(tapply(w[, "sil_width"], w[, "cluster"], mean)),
         avg.width = mean(w[, "sil_width"]))
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

##' Per-sample silhouette widths
##'
##' Extract the fine-grained silhouette information of one `k` from an `nk()`
##' result: one row per sample, with the cluster the sample was assigned to, its
##' neighbour cluster and its silhouette width.
##'
##' @title silinfo_widths
##' @param x a `silinfo` object, as returned by [nk()]
##' @param k a single value among the candidate `k` used in [nk()]
##' @return a `data.frame` with one row per sample and the columns `sample`,
##' `cluster`, `neighbor` and `sil_width`. The rows keep the order in which the
##' clusterer returned them -- for `cluster::pam()` that is by cluster and, within
##' a cluster, by decreasing `sil_width` -- so the rows should be aligned by
##' `sample` rather than by position. The per-cluster average silhouette widths
##' are attached as the `"clus.avg.widths"` attribute, and are also available as
##' `x$silinfo[[i]]$clus.avg.widths`, where `i` is the position of `k` in `x$k`.
##' @seealso [nk()], [autoplot()]
##' @examples
##' x <- nk(iris[,-5], 2:4)
##' head(silinfo_widths(x, 3))
##' attr(silinfo_widths(x, 3), "clus.avg.widths")
##' @export
##' @author Guangchuang Yu
silinfo_widths <- function(x, k) {
    if (!inherits(x, "silinfo")) {
        stop("`silinfo_widths()`: 'x' must be a 'silinfo' object, as returned by `nk()`.",
             call. = FALSE)
    }
    if (missing(k)) {
        stop("`silinfo_widths()`: 'k' must be provided; it must be one of the candidate k values used in `nk()`.",
             call. = FALSE)
    }
    if (length(k) != 1L || !is.numeric(k) || is.na(k) || !is.finite(k)) {
        stop("`silinfo_widths()`: 'k' must be a single number.", call. = FALSE)
    }

    i <- which(x$k == k)
    if (length(i) == 0L) {
        stop(sprintf("`silinfo_widths()`: k = %s is not among the candidate k values used in nk(): %s",
                     k, paste(x$k, collapse = ", ")), call. = FALSE)
    }

    si <- x$silinfo[[i[1L]]]
    w <- si$widths
    need <- c("cluster", "neighbor", "sil_width")
    if (is.null(w) || !all(need %in% colnames(w))) {
        stop(sprintf("`silinfo_widths()`: the silhouette information of k = %s does not have the expected columns (%s).",
                     k, paste(need, collapse = ", ")), call. = FALSE)
    }
    if (is.null(rownames(w))) {
        rownames(w) <- as.character(seq_len(nrow(w)))
    }

    res <- data.frame(sample = rownames(w),
                      cluster = as.vector(w[, "cluster"]),
                      neighbor = as.vector(w[, "neighbor"]),
                      sil_width = as.vector(w[, "sil_width"]),
                      stringsAsFactors = FALSE)
    attr(res, "clus.avg.widths") <- si$clus.avg.widths
    res
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

