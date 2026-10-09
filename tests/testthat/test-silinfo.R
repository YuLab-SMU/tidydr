test_that("nk() returns a silinfo object", {
    x <- nk(iris[,-5], 2:4)
    expect_s3_class(x, "silinfo")
    expect_equal(x$k, 2:4)
    expect_length(x$silinfo, 3)
})

test_that("summary.silinfo returns data.frame with K and Silhouette", {
    x <- nk(iris[,-5], 2:4)
    s <- summary(x)
    expect_s3_class(s, "data.frame")
    expect_equal(colnames(s), c("K", "Silhouette"))
    expect_equal(nrow(s), 3)
    expect_true(all(s$Silhouette > 0 & s$Silhouette <= 1))
})

test_that("print.silinfo works", {
    x <- nk(iris[,-5], 2:4)
    expect_output(print(x), "Silhouette information")
    expect_output(print(x), "Best K")
})

## ---- U2: k boundary and data contract -----------------------------------

test_that("nk() rejects k = 1 with a clear message", {
    expect_error(nk(iris[,-5], 1), "at least 2")
    expect_error(nk(iris[,-5], 1), "undefined for k = 1")
})

test_that("nk() rejects a k vector that contains 1", {
    expect_error(nk(iris[,-5], c(2, 1)), "at least 2")
})

test_that("nk() rejects k >= n with a clear message", {
    expect_error(nk(iris[,-5], 150), "smaller than the number of samples")
    expect_error(nk(iris[,-5], 200), "smaller than the number of samples")
})

test_that("nk() rejects non-integer / non-numeric / missing / NA k", {
    expect_error(nk(iris[,-5], 2.5), "must be integers")
    expect_error(nk(iris[,-5], "2"), "must be a numeric vector")
    expect_error(nk(iris[,-5]), "must be provided")
    expect_error(nk(iris[,-5], NA_real_), "must not contain NA")
})

test_that("nk() rejects invalid data", {
    expect_error(nk(NULL, 2:3), "must not be NULL")
    expect_error(nk(iris, 2:3), "Non-numeric")
    expect_error(nk(matrix(letters[1:4], nrow = 2), 2), "numeric matrix")
    expect_error(nk(list(1, 2, 3), 2), "'dist' object")
    d <- iris[,-5]; d[1,1] <- NA
    expect_error(nk(d, 2:3), "missing")
})

test_that("nk() still accepts a 'dist' object (pam supports dissimilarities)", {
    dd <- as.dist(dist(iris[,1:4]))
    x <- nk(dd, 2:3)
    expect_s3_class(x, "silinfo")
    expect_equal(x$k, 2:3)
    expect_equal(nrow(summary(x)), 2)
    expect_output(print(x), "Best K")
    expect_s3_class(autoplot(x), "ggplot")
    expect_s3_class(autoplot(x, k = 2), "ggplot")
})

test_that("nk() rejects a dist object containing NA", {
    m <- as.matrix(dist(iris[1:5, 1:4]))
    m[1,2] <- m[2,1] <- NA
    expect_error(nk(as.dist(m), 2), "missing")
})

test_that("nk() output is printable, summarisable and plottable for valid k", {
    x <- nk(iris[,-5], 2:4)
    expect_output(print(x), "Silhouette information")
    expect_output(print(x), "Best K")

    s <- summary(x)
    expect_s3_class(s, "data.frame")
    expect_equal(nrow(s), 3)

    p <- autoplot(x)
    expect_s3_class(p, "ggplot")

    p2 <- autoplot(x, k = 3)
    expect_s3_class(p2, "ggplot")
})

## ---- F1: pluggable clustering methods -----------------------------------

test_that("nk() default path is bit-for-bit the pam silhouette information", {
    x <- iris[,-5]
    obj <- nk(x, 2:4)
    for (i in seq_along(2:4)) {
        ref <- cluster::pam(x, k = (2:4)[i])$silinfo
        expect_identical(obj$silinfo[[i]], ref)
    }
    s <- summary(obj)
    expect_equal(s$K, 2:4)
    expect_equal(s$Silhouette,
                 c(0.68578817126171943, 0.55281901235640996, 0.48969717913026017))
})

test_that("nk() supports an alternative clusterer via 'fun' (kmeans)", {
    x <- iris[,-5]
    set.seed(1)
    obj <- nk(x, 3, fun = stats::kmeans)
    expect_s3_class(obj, "silinfo")
    expect_equal(nrow(summary(obj)), 1)

    set.seed(1)
    km <- stats::kmeans(x, 3)
    ref <- cluster::silhouette(km$cluster, stats::dist(x))
    expect_equal(obj$silinfo[[1]]$avg.width, mean(ref[, "sil_width"]))
    expect_equal(colnames(obj$silinfo[[1]]$widths),
                 c("cluster", "neighbor", "sil_width"))
    expect_equal(length(obj$silinfo[[1]]$clus.avg.widths), 3)
    expect_output(print(obj), "Best K")
    expect_s3_class(autoplot(obj), "ggplot")
    expect_s3_class(autoplot(obj, k = 3), "ggplot")
})

test_that("nk() cuts a hierarchical method automatically (hclust)", {
    x <- iris[,-5]
    obj <- nk(x, 2:4, fun = stats::hclust)
    expect_s3_class(obj, "silinfo")
    expect_equal(obj$k, 2:4)
    ref <- cluster::silhouette(
        stats::cutree(stats::hclust(stats::dist(x)), 3), stats::dist(x))
    expect_equal(obj$silinfo[[2]]$avg.width, mean(ref[, "sil_width"]))
    expect_s3_class(autoplot(obj), "ggplot")
})

test_that("nk() accepts a 'fun' that returns a plain label vector", {
    x <- iris[,-5]
    f <- function(data, k) stats::cutree(stats::hclust(stats::dist(data)), k)
    obj <- nk(x, 3, fun = f)
    expect_equal(obj$silinfo[[1]]$avg.width,
                 nk(x, 3, fun = stats::hclust)$silinfo[[1]]$avg.width)
})

test_that("nk() supports a dissimilarity-first method that is not named 'd' via a wrapper", {
    skip_if_not_installed("cluster")
    x <- iris[,-5]
    ## cluster::agnes() takes the dissimilarity as its first argument, but under
    ## the name 'x', so the argument-based heuristic reads it as taking a cluster
    ## count. Documented workaround: make 'k' an argument of the wrapper.
    f <- function(z, k) stats::cutree(cluster::agnes(stats::dist(z)), k)
    obj <- nk(x, 2:3, fun = f)
    expect_s3_class(obj, "silinfo")
    expect_equal(obj$k, 2:3)
    expect_equal(nrow(summary(obj)), 2)
    expect_equal(obj$silinfo[[2]]$avg.width,
                 nk(x, 3, fun = function(z, k) stats::cutree(cluster::agnes(stats::dist(z)), k))$silinfo[[1]]$avg.width)
})

test_that("nk() fails for a dissimilarity-first method whose first argument is not 'd' (documented)", {
    skip_if_not_installed("cluster")
    x <- iris[,-5]
    ## Documented limitation of the argument-based heuristic (see `?nk`, the `fun`
    ## parameter): `cluster::agnes()` and `diana()` take the dissimilarity as their
    ## first argument under the name `x`, so `nk_takes_k()` reads them as taking a
    ## cluster count.  `nk()` therefore hands them the raw data matrix, which agnes
    ## reports as a "non-square matrix" before the fit fails.  The call is made
    ## twice so each half is a *live* assertion: nesting `expect_warning()` inside
    ## `expect_error()` would leave the warning claim unevaluated (the error unwinds
    ## first).  `suppressWarnings()` on the second call is needed because
    ## `expect_error()` does not muffle the warning agnes emits before it fails --
    ## without it the suite's warning count is 1.
    expect_warning(
        tryCatch(nk(x, 3, fun = cluster::agnes), error = function(e) NULL),
        "non-square matrix"
    )
    expect_error(
        suppressWarnings(nk(x, 3, fun = cluster::agnes)),
        "clustering with 'fun' failed"
    )
})

test_that("nk() forwards extra arguments to 'fun'", {
    x <- iris[,-5]
    obj <- nk(x, 3, fun = stats::hclust, method = "single")
    ref <- cluster::silhouette(
        stats::cutree(stats::hclust(stats::dist(x), method = "single"), 3),
        stats::dist(x))
    expect_equal(obj$silinfo[[1]]$avg.width, mean(ref[, "sil_width"]))
})

test_that("nk() accepts a 'dist' input together with 'fun'", {
    dd <- as.dist(dist(iris[,1:4]))
    obj <- nk(dd, 2:3, fun = stats::hclust)
    expect_s3_class(obj, "silinfo")
    expect_equal(obj$k, 2:3)
})

test_that("nk() rejects a 'fun' that is not a function", {
    expect_error(nk(iris[,-5], 2:3, fun = 42), "must be a function")
})

test_that("nk() reports a clear error when 'fun' fails", {
    expect_error(nk(iris[,-5], 2:3, fun = function(data, k) stop("boom")),
                 "clustering with 'fun' failed")
    expect_error(nk(iris[,-5], 2:3, fun = function(data, k) stop("boom")),
                 "boom")
})

test_that("nk() rejects a 'fun' returning wrong-length or single-cluster labels", {
    expect_error(nk(iris[,-5], 3, fun = function(data, k) rep(1L, 5)),
                 "5 cluster labels")
    expect_error(nk(iris[,-5], 3, fun = function(data, k) rep(1L, 150)),
                 "single cluster")
})

test_that("nk() rejects an object without extractable labels", {
    expect_error(nk(iris[,-5], 3, fun = function(data, k) list(foo = 1)),
                 "cannot extract cluster labels")
})

## ---- F5: fine-grained silhouette export ----------------------------------

test_that("silinfo_widths() returns one row per sample", {
    x <- nk(iris[,-5], 2:4)
    w <- silinfo_widths(x, 3)
    expect_s3_class(w, "data.frame")
    expect_equal(colnames(w), c("sample", "cluster", "neighbor", "sil_width"))
    expect_equal(nrow(w), 150)

    ## the same numbers as the widths matrix that nk() stores
    ref <- x$silinfo[[2]]$widths
    expect_equal(w$sample, rownames(ref))
    expect_equal(w$cluster, as.vector(ref[, "cluster"]))
    expect_equal(w$neighbor, as.vector(ref[, "neighbor"]))
    expect_equal(w$sil_width, as.vector(ref[, "sil_width"]))
})

test_that("silinfo_widths() exposes the per-cluster averages", {
    x <- nk(iris[,-5], 2:4)
    w <- silinfo_widths(x, 3)
    expect_equal(attr(w, "clus.avg.widths"), x$silinfo[[2]]$clus.avg.widths)
    ## and they are consistent with the per-sample values
    expect_equal(attr(w, "clus.avg.widths"),
                 as.numeric(tapply(w$sil_width, w$cluster, mean)))
})

test_that("silinfo_widths() works for every candidate k", {
    x <- nk(iris[,-5], 2:4)
    for (k in 2:4) {
        w <- silinfo_widths(x, k)
        expect_equal(nrow(w), 150)
        expect_equal(length(unique(w$cluster)), k)
    }
})

test_that("silinfo_widths() works for a non-pam clusterer", {
    set.seed(1)
    x <- nk(iris[,-5], 3, fun = stats::kmeans)
    w <- silinfo_widths(x, 3)
    expect_equal(nrow(w), 150)
    expect_equal(length(unique(w$cluster)), 3)
})

test_that("silinfo_widths() validates its input", {
    x <- nk(iris[,-5], 2:4)
    expect_error(silinfo_widths(iris, 3), "must be a 'silinfo' object")
    expect_error(silinfo_widths(x), "must be provided")
    expect_error(silinfo_widths(x, 5), "not among the candidate k values")
    expect_error(silinfo_widths(x, c(2, 3)), "single number")
    expect_error(silinfo_widths(x, NA_real_), "single number")
})

## ---- F5: existing autoplot.silinfo behaviour is preserved ----------------

test_that("autoplot.silinfo(x) is still the silhouette-versus-k line plot", {
    x <- nk(iris[,-5], 2:4)
    p <- autoplot(x)
    expect_s3_class(p, "ggplot")
    expect_equal(p$data$K, summary(x)$K)
    expect_equal(p$data$Silhouette, summary(x)$Silhouette)
    expect_true(inherits(p$layers[[1]]$geom, "GeomLine"))
    expect_true(inherits(p$layers[[2]]$geom, "GeomPoint"))
    ## 'type' is inferred from 'k'
    expect_equal(autoplot(x, type = "k")$data$Silhouette,
                 summary(x)$Silhouette)
})

test_that("autoplot.silinfo(x, k=3) is still a PCA coloured by cluster", {
    x <- nk(iris[,-5], 2:4)
    p <- autoplot(x, k = 3)
    expect_s3_class(p, "ggplot")
    expect_equal(nrow(p$data), 150)
    expect_true(all(c("PC1", "PC2", "cluster") %in% colnames(p$data)))
    expect_equal(nlevels(p$data$cluster), 3)
    expect_true(inherits(p$layers[[1]]$geom, "GeomPoint"))
    expect_equal(autoplot(x, k = 3, type = "pca")$data, p$data)
})

test_that("autoplot.silinfo(x, k=) aligns clusters by sample name, not by position", {
    x <- nk(iris[,-5], 3)
    p <- autoplot(x, k = 3)
    ## pam() stores 'widths' sorted by cluster, so aligning by position is wrong
    ## for ~16% of the iris samples; the labels must follow the sample names
    truth <- unname(cluster::pam(iris[,-5], 3)$clustering)
    got <- as.integer(as.character(p$data$cluster))
    expect_equal(got, truth)
})

test_that("the PCA alignment falls back to positional order when names do not match", {
    x <- nk(iris[,-5], 3)
    rownames(x$silinfo[[1]]$widths) <- paste0("z", seq_len(150))
    p <- autoplot(x, k = 3)
    expect_equal(nrow(p$data), 150)
    expect_equal(as.integer(as.character(p$data$cluster)),
                 as.vector(x$silinfo[[1]]$widths[, "cluster"]))
})

test_that("autoplot.silinfo validates 'type' and the k it needs", {
    x <- nk(iris[,-5], 2:4)
    expect_error(autoplot(x, type = "foo"), "'arg' should be one of")
    expect_error(autoplot(x, type = "silhouette"), "'k' must be provided")
    expect_error(autoplot(x, k = 5), "not among the candidate k values")
    expect_error(autoplot(x, k = 5, type = "silhouette"),
                 "not among the candidate k values")
})

## ---- F5: silhouette bar plot ---------------------------------------------

test_that("autoplot.silinfo(type = 'silhouette') draws the classic bar plot", {
    x <- nk(iris[,-5], 2:4)
    p <- autoplot(x, k = 3, type = "silhouette")
    expect_s3_class(p, "ggplot")
    expect_equal(colnames(p$data), c("sample", "cluster", "neighbor", "sil_width"))
    expect_equal(nrow(p$data), 150)

    ## one panel per cluster
    expect_true(inherits(p$facet, "FacetGrid"))
    expect_equal(nlevels(p$data$cluster), 3)

    ## samples are grouped by cluster and ordered by decreasing sil_width within
    ## each cluster
    cl <- as.integer(p$data$cluster)
    expect_false(is.unsorted(cl))
    for (g in split(p$data$sil_width, cl)) {
        expect_false(is.unsorted(rev(g)))
    }

    ## the bars carry the same values as the accessor
    expect_setequal(p$data$sil_width, silinfo_widths(x, 3)$sil_width)
    expect_no_error(ggplot2::ggplot_build(p))
})

test_that("the silhouette bar plot works for a non-pam clusterer", {
    set.seed(1)
    x <- nk(iris[,-5], 3, fun = stats::kmeans)
    p <- autoplot(x, k = 3, type = "silhouette")
    expect_s3_class(p, "ggplot")
    expect_equal(nrow(p$data), 150)
    expect_no_error(ggplot2::ggplot_build(p))
})
