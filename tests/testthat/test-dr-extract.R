test_that("dr_extract.prcomp extracts coordinates and eigenvalues", {
    p <- stats::prcomp(iris[,1:4])
    res <- dr_extract(p)
    expect_equal(dim(res$drdata), c(150, 4))
    expect_false(is.null(res$eigenvalue))
    expect_equal(length(res$eigenvalue), 4)
    expect_null(res$stress)
})

test_that("dr_extract.default extracts 'points' field", {
    fake <- list(points = matrix(1:10, nrow = 5, ncol = 2),
                 eig = c(3, 1))
    res <- dr_extract(fake)
    expect_equal(dim(res$drdata), c(5, 2))
    expect_equal(as.numeric(res$eigenvalue), c(3, 1))
})

test_that("dr_extract.default warns when no 'points' field", {
    expect_warning(res <- dr_extract(list(eig = c(3, 1))),
                   "no 'points' field")
    expect_null(res$drdata)
})

test_that("dr_extract.default extracts stress when present", {
    fake <- list(points = matrix(1:10, nrow = 5, ncol = 2),
                 stress = 0.12345)
    res <- dr_extract(fake)
    expect_equal(res$stress, format(0.12345, digits = 4))
})

## ---- U4: numeric-matrix fallback ----------------------------------------

test_that("dr_extract.matrix accepts a numeric matrix with >= 2 columns", {
    m <- matrix(1:10, nrow = 5, ncol = 2)
    res <- dr_extract(m)
    expect_equal(dim(res$drdata), c(5, 2))
    expect_null(res$eigenvalue)
    expect_null(res$stress)
})

test_that("dr_extract.matrix rejects a non-numeric matrix", {
    expect_error(dr_extract(matrix(letters[1:4], nrow = 2)), "numeric matrix")
})

test_that("dr_extract.matrix rejects a single-column matrix", {
    expect_error(dr_extract(matrix(1:5, nrow = 5, ncol = 1)), "at least 2 columns")
})

test_that("S3 dispatch prefers a classed method over dr_extract.matrix", {
    ## A 1-column matrix would be rejected by dr_extract.matrix(); if dispatch
    ## reaches dr_extract.uwot instead, the call succeeds. This pins down the
    ## dispatch order ('uwot' precedes 'matrix' in the class chain).
    m <- matrix(1:5, nrow = 5, ncol = 1)
    class(m) <- c("uwot", "matrix", "array")
    res <- dr_extract(m)
    expect_equal(dim(res$drdata), c(5, 1))
})

test_that("dr() works for stats::cmdscale() (bare matrix result)", {
    dd <- as.dist(dist(iris[,1:4]))
    x <- dr(dd, stats::cmdscale)
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 2))
})

test_that("dr() works for a wrapped method returning a bare matrix", {
    skip_if_not_installed("uwot")
    x <- dr(iris[,1:4], function(d) uwot::umap(d))
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 2))
})

test_that("dr(iris[,1:4], uwot::umap) dispatches to dr_extract.uwot", {
    skip_if_not_installed("uwot")
    ## pin the dispatch: a plain 150x2 result looks the same whether it came
    ## from dr_extract.uwot or dr_extract.matrix, so instrument the method.
    ns <- asNamespace("tidydr")
    hits <- character()
    suppressMessages(trace("dr_extract.uwot",
                           tracer = function() hits <<- c(hits, "uwot"),
                           print = FALSE, where = ns))
    on.exit(suppressMessages(untrace("dr_extract.uwot", where = ns)), add = TRUE)

    x <- dr(iris[,1:4], uwot::umap)
    expect_equal(hits, "uwot")
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 2))
})
