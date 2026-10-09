## ---- F2: dr_compare() ----------------------------------------------------

test_that("dr_compare() runs one method and reports it as ok", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp))
    expect_s3_class(x, "DrCompare")
    expect_named(x$results, "pca")
    expect_s3_class(x$results$pca, "DrResult")
    expect_equal(x$summary$method, "pca")
    expect_equal(x$summary$status, "ok")
    expect_equal(x$summary$n, 150)
    expect_equal(x$summary$k, 4)
    expect_true(x$summary$has_eigenvalue)
    expect_false(x$summary$has_stress)
    expect_true(is.na(x$summary$error))
})

test_that("dr_compare() summary has the documented columns", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp))
    expect_s3_class(x$summary, "data.frame")
    expect_equal(colnames(x$summary),
                 c("method", "status", "n", "k",
                   "has_eigenvalue", "has_stress", "error"))
})

test_that("dr_compare() defaults to a single prcomp method", {
    x <- dr_compare(iris[,1:4])
    expect_named(x$results, "prcomp")
    expect_equal(x$summary$status, "ok")
})

test_that("dr_compare() gives the same coordinates as calling dr() directly", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp))
    expect_equal(x$results$pca$drdata, dr(iris[,1:4], stats::prcomp)$drdata)
})

test_that("dr_compare() compares methods that return different numbers of dimensions", {
    skip_if_not_installed("uwot")
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp, umap = uwot::umap))
    expect_equal(length(x$results), 2)
    expect_equal(dim(x$results$pca$drdata), c(150, 4))
    expect_equal(dim(x$results$umap$drdata), c(150, 2))
    expect_equal(x$summary$status, c("ok", "ok"))
    expect_equal(x$summary$k, c(4, 2))
    expect_equal(x$summary$n, c(150, 150))
    expect_equal(x$summary$has_eigenvalue, c(TRUE, FALSE))
    expect_false(any(x$summary$has_stress))
    expect_true(all(is.na(x$summary$error)))
})

test_that("dr_compare() isolates a failing method and keeps the others", {
    skip_if_not_installed("Rtsne")
    ## Rtsne() refuses duplicated points and iris has duplicated rows, so this
    ## is a genuine upstream failure rather than a simulated one.
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp, tsne = Rtsne::Rtsne))
    expect_equal(length(x$results), 2)
    expect_s3_class(x$results$pca, "DrResult")
    expect_true(inherits(x$results$tsne, "error"))
    expect_equal(x$summary$status, c("ok", "failed"))
    expect_true(is.na(x$summary$error[1]))
    expect_match(x$summary$error[2], "duplicates", ignore.case = TRUE)
    ## a failed method gets no placeholder coordinates
    expect_true(is.na(x$summary$n[2]))
    expect_true(is.na(x$summary$k[2]))
    expect_true(is.na(x$summary$has_eigenvalue[2]))
})

test_that("dr_compare() accepts per-method 'args'", {
    skip_if_not_installed("Rtsne")
    x <- dr_compare(iris[,1:4],
                    list(tsne = list(fun = Rtsne::Rtsne,
                                     args = list(check_duplicates = FALSE)),
                         pca = stats::prcomp))
    expect_equal(x$summary$status, c("ok", "ok"))
    expect_equal(dim(x$results$tsne$drdata), c(150, 2))
})

test_that("dr_compare() forwards '...' to every method", {
    x <- dr_compare(iris[,1:4],
                    list(pca = stats::prcomp, pca2 = stats::prcomp),
                    center = FALSE, scale. = TRUE)
    ref <- dr(iris[,1:4], stats::prcomp, center = FALSE, scale. = TRUE)
    expect_equal(x$results$pca$drdata, ref$drdata)
    expect_equal(x$results$pca2$drdata, ref$drdata)
    ## the assertion above only discriminates if '...' really changed the result
    expect_false(isTRUE(all.equal(ref$drdata,
                                  dr(iris[,1:4], stats::prcomp)$drdata)))
})

test_that("dr_compare() flags a method with too few dimensions", {
    x <- dr_compare(iris[, 1, drop = FALSE], list(pca = stats::prcomp))
    expect_equal(x$summary$status, "insufficient_dims")
    expect_equal(x$summary$k, 1)
    expect_equal(x$summary$n, 150)
    expect_match(x$summary$error, "requires at least 2")
    ## the method itself did succeed, only the requested dims are unavailable
    expect_s3_class(x$results$pca, "DrResult")
})

test_that("dr_compare() accepts a 'dist' input", {
    dd <- as.dist(dist(iris[,1:4]))
    x <- dr_compare(dd, list(cmdscale = stats::cmdscale))
    expect_equal(x$summary$status, "ok")
    expect_equal(x$summary$k, 2)
    expect_equal(nrow(x$results$cmdscale$drdata), 150)
})

test_that("dr_compare() validates 'funs'", {
    expect_error(dr_compare(iris[,1:4], list(stats::prcomp)), "must be named")
    expect_error(dr_compare(iris[,1:4], list()), "non-empty list")
    expect_error(dr_compare(iris[,1:4], "not a list"), "non-empty list")
    expect_error(dr_compare(iris[,1:4], list(a = stats::prcomp, a = stats::cmdscale)),
                 "must be unique")
    expect_error(dr_compare(iris[,1:4], list(a = list(fun = 1))),
                 "must be a function")
    expect_error(dr_compare(iris[,1:4], list(a = list(fun = stats::prcomp, args = 1))),
                 "'args' of a method must be a list")
})

test_that("dr_compare() validates 'dim'", {
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = 1),
                 "length 2")
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = "1:2"),
                 "length 2")
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = c(1, 1)),
                 "distinct")
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = c(0, 1)),
                 "positive integers")
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = c(1.5, 2)),
                 "positive integers")
    expect_error(dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = c(1, NA)),
                 "positive integers")
})

test_that("dr_compare() validates 'data' with the same contract as dr()", {
    expect_error(dr_compare(NULL, list(pca = stats::prcomp)), "must not be NULL")
    expect_error(dr_compare(1:10, list(pca = stats::prcomp)), "bare vector")
    expect_error(dr_compare(iris, list(pca = stats::prcomp)), "Non-numeric")
})

test_that("autoplot.DrCompare facets the successful methods", {
    skip_if_not_installed("uwot")
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp, umap = uwot::umap))
    p <- autoplot(x)
    expect_s3_class(p, "ggplot")
    expect_true(inherits(p$facet, "FacetWrap"))
    expect_setequal(unique(p$data$method), c("pca", "umap"))
    expect_equal(nrow(p$data), 300)
    expect_equal(colnames(p$data)[1:2], c("Dim1", "Dim2"))
    ## the two panels keep independent ranges ("free" scales)
    expect_no_error(ggplot2::ggplot_build(p))
    built <- ggplot2::ggplot_build(p)
    expect_equal(length(built$layout$panel_params), 2)
})

test_that("autoplot.DrCompare plots only the methods that worked", {
    skip_if_not_installed("Rtsne")
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp, tsne = Rtsne::Rtsne))
    p <- autoplot(x)
    expect_equal(unique(p$data$method), "pca")
    expect_equal(nrow(p$data), 150)
})

test_that("autoplot.DrCompare errors when nothing is plottable", {
    x <- dr_compare(iris[, 1, drop = FALSE], list(pca = stats::prcomp))
    expect_error(autoplot(x), "none of the methods")
})

test_that("autoplot.DrCompare honours a non-default 'dim'", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp), dim = 2:3)
    expect_equal(x$summary$status, "ok")
    p <- autoplot(x)
    expect_equal(p$data$Dim1, x$results$pca$drdata[[2]])
    expect_equal(p$data$Dim2, x$results$pca$drdata[[3]])
})

test_that("dr_compare() metadata becomes a column of the plot", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp),
                    metadata = iris$Species)
    p <- autoplot(x, aes(color = .group))
    expect_true(".group" %in% colnames(p$data))
    expect_equal(p$data$.group, iris$Species)
})

test_that("print.DrCompare shows the summary table", {
    x <- dr_compare(iris[,1:4], list(pca = stats::prcomp))
    expect_output(print(x), "Comparison of 1 dimensionality reduction method")
    expect_output(print(x), "pca")
    expect_output(print(x), "ok")
    ## returns the object invisibly
    out <- capture.output(res <- print(x))
    expect_identical(res, x)
    expect_true(any(grepl("has_eigenvalue", out)))
})
