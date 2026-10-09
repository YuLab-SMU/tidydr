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

## ---- F4: every method advertised by available_methods() -------------------
##
## One block per entry of available_methods(), exercised end-to-end through
## dr(). Methods whose package is not installed are skipped, so the suite stays
## green on a minimal installation; where the package is present the assertions
## below are the real, measured behaviour.
##
## Sizes are pinned to what was measured locally (iris, n = 150):
##   prcomp 150x4 | Rtsne 150x2 | umap/tumap/lvish 150x2 | cmdscale 150x2
##   sammon 149x2 | metaMDS 149x2 | pcoa 150x4 | smacof::mds 150x2
##   wcmdscale 150x4 | ecodist::pco 150x150 | labdsv::pco 150x2
##   ade4::dudi.pco 150x4
## Methods whose dimension count is an upstream implementation detail (the
## "return every eigenvector" family) are only required to keep 150 rows and at
## least 2 columns, so a change there is not reported as a tidydr failure.

## -- data-matrix methods ----------------------------------------------------

test_that("dr() works for stats::prcomp()", {
    x <- dr(iris[,1:4], stats::prcomp)
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 4))
    expect_equal(length(x$eigenvalue), 4)
    expect_null(x$stress)
})

test_that("dr() works for Rtsne::Rtsne()", {
    skip_if_not_installed("Rtsne")
    ## upstream: Rtsne() refuses duplicated points and iris has duplicated rows
    expect_error(dr(iris[,1:4], Rtsne::Rtsne), "duplicates")

    x <- dr(iris[,1:4], Rtsne::Rtsne, check_duplicates = FALSE)
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 2))
    expect_null(x$eigenvalue)
})

test_that("dr() works for uwot::umap(), uwot::tumap() and uwot::lvish()", {
    skip_if_not_installed("uwot")
    for (f in list(uwot::umap, uwot::tumap, uwot::lvish)) {
        x <- dr(iris[,1:4], f)
        expect_s3_class(x, "DrResult")
        expect_equal(dim(x$drdata), c(150, 2))
        expect_null(x$eigenvalue)
        expect_null(x$stress)
    }
})

test_that("uwot::lvish() fails when the sample is smaller than its perplexity", {
    skip_if_not_installed("uwot")
    ## upstream limitation, pinned so it is not mistaken for a tidydr bug
    expect_error(dr(iris[1:20, 1:4], uwot::lvish), "perplexity")
})

## -- distance methods -------------------------------------------------------

test_that("dr() works for stats::cmdscale()", {
    dd <- as.dist(dist(iris[,1:4]))
    x <- dr(dd, stats::cmdscale)
    expect_equal(dim(x$drdata), c(150, 2))

    ## cmdscale(eig = TRUE) returns a list instead of a matrix, which takes the
    ## dr_extract.default() path
    y <- dr(dd, stats::cmdscale, eig = TRUE)
    expect_equal(dim(y$drdata), c(150, 2))
    expect_equal(length(y$eigenvalue), 150)
})

test_that("dr() works for MASS::sammon()", {
    skip_if_not_installed("MASS")
    dd <- as.dist(dist(iris[,1:4]))
    ## upstream: the raw iris distance contains a zero/negative distance
    expect_error(dr(dd, MASS::sammon, trace = FALSE), "zero or negative")

    ded <- iris[!duplicated(iris[,1:4]), 1:4]
    x <- dr(as.dist(dist(ded)), MASS::sammon, trace = FALSE)
    expect_equal(dim(x$drdata), c(149, 2))
    expect_false(is.null(x$stress))
})

test_that("dr() works for ape::pcoa()", {
    skip_if_not_installed("ape")
    x <- dr(as.dist(dist(iris[,1:4])), ape::pcoa)
    expect_equal(dim(x$drdata), c(150, 4))
    expect_equal(length(x$eigenvalue), 4)
})

test_that("dr() works for vegan::metaMDS()", {
    skip_if_not_installed("vegan")
    ded <- iris[!duplicated(iris[,1:4]), 1:4]
    x <- dr(as.dist(dist(ded)), vegan::metaMDS, trace = 0, try = 1, trymax = 1)
    expect_equal(dim(x$drdata), c(149, 2))
    expect_false(is.null(x$stress))
})

test_that("dr() works for smacof::mds()", {
    skip_if_not_installed("smacof")
    x <- dr(as.dist(dist(iris[,1:4])), smacof::mds)
    expect_equal(dim(x$drdata), c(150, 2))
    expect_false(is.null(x$stress))
})

test_that("dr() works for vegan::wcmdscale()", {
    skip_if_not_installed("vegan")
    ## wcmdscale() returns a bare matrix, so it is handled by dr_extract.matrix();
    ## it keeps the dimensions with a positive eigenvalue (4 for iris)
    x <- dr(as.dist(dist(iris[,1:4])), vegan::wcmdscale)
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 4))
    expect_null(x$eigenvalue)
})

test_that("dr() works for ecodist::pco()", {
    skip_if_not_installed("ecodist")
    x <- dr(as.dist(dist(iris[,1:4])), ecodist::pco)
    expect_s3_class(x, "DrResult")
    ## ecodist::pco() returns every eigenvector, not just the first few
    expect_equal(dim(x$drdata), c(150, 150))
    expect_equal(length(x$eigenvalue), 150)
})

test_that("dr() works for labdsv::pco()", {
    skip_if_not_installed("labdsv")
    x <- dr(as.dist(dist(iris[,1:4])), labdsv::pco)
    expect_s3_class(x, "DrResult")
    ## labdsv::pco() returns k = 2 axes by default, but the full eigenvalue vector
    expect_equal(dim(x$drdata), c(150, 2))
    expect_equal(length(x$eigenvalue), 150)
})

test_that("dr() works for ade4::dudi.pco()", {
    skip_if_not_installed("ade4")
    ## scannf = FALSE is required; with the default dudi.pco() asks for the
    ## number of axes interactively
    x <- dr(as.dist(dist(iris[,1:4])), ade4::dudi.pco, scannf = FALSE, nf = 2)
    expect_s3_class(x, "DrResult")
    expect_equal(dim(x$drdata), c(150, 4))
    expect_equal(length(x$eigenvalue), 4)
})
