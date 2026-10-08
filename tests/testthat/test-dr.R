test_that("dr() returns a DrResult with correct structure", {
    x <- dr(iris[,1:4], prcomp)
    expect_s3_class(x, "DrResult")
    expect_equal(nrow(x$drdata), 150)
    expect_true(all(grepl("^Dim", colnames(x$drdata))))
    expect_false(is.null(x$eigenvalue))
    expect_null(x$stress)
})

test_that("print.DrResult works with eigenvalue path", {
    x <- dr(iris[,1:4], prcomp)
    expect_output(print(x), "Eigen value")
    expect_output(print(x), "Dimensionality reduction")
    expect_output(print(x), "150 x 4")
})

test_that("print.DrResult works with non-NULL stress", {
    fake <- structure(
        list(data = iris[,1:4],
             drdata = as.data.frame(stats::cmdscale(dist(iris[,1:4]))),
             eigenvalue = NULL,
             stress = "0.1234"),
        class = "DrResult"
    )
    expect_output(print(fake), "Stress")
    expect_output(print(fake), "0.1234")
    expect_output(print(fake), "150 x 2")
})

test_that("dr() errors clearly on unsupported result", {
    fake_fun <- function(d, ...) list(foo = 1)
    expect_error(suppressWarnings(dr(iris[,1:4], fake_fun)),
                 "could not extract")
})

## ---- U1: input contract --------------------------------------------------

test_that("dr() rejects NULL data with a tidydr-flavoured message", {
    expect_error(dr(NULL, prcomp), "must not be NULL")
})

test_that("dr() rejects a bare numeric vector and points to as.dist()", {
    expect_error(dr(1:10, prcomp), "bare vector")
    expect_error(dr(1:10, prcomp), "as.dist")
})

test_that("dr() rejects data containing NA / NaN / Inf", {
    d <- iris[1:5, 1:4]; d[1,1] <- NA
    expect_error(dr(d, prcomp), "missing")

    d2 <- iris[1:5, 1:4]; d2[1,1] <- Inf
    expect_error(dr(d2, prcomp), "infinite")

    d3 <- iris[1:5, 1:4]; d3[1,1] <- NaN
    expect_error(dr(d3, prcomp), "missing")
})

test_that("dr() rejects a dist object containing NA", {
    m <- as.matrix(dist(iris[1:5, 1:4]))
    m[1,2] <- m[2,1] <- NA
    dd <- as.dist(m)
    expect_error(dr(dd, function(d) stats::cmdscale(d)), "missing")
})

test_that("dr() rejects data.frame with non-numeric columns and names them", {
    expect_error(dr(iris, prcomp), "Non-numeric")
    expect_error(dr(iris, prcomp), "Species")
    ## message should be tidydr's, not prcomp's
    expect_error(dr(iris, prcomp), "`dr\\(\\)`")
})

test_that("dr() rejects a non-numeric matrix", {
    expect_error(dr(matrix(letters[1:4], nrow = 2), prcomp), "numeric matrix")
})

test_that("dr() rejects unsupported data types", {
    expect_error(dr(list(1, 2, 3), prcomp), "unsupported 'data' type")
})

test_that("dr() still accepts matrix, numeric data.frame and dist objects", {
    expect_s3_class(dr(iris[,1:4], prcomp), "DrResult")
    expect_s3_class(dr(as.matrix(iris[,1:4]), prcomp), "DrResult")
    expect_s3_class(dr(iris[,1:4, drop = FALSE], prcomp), "DrResult")

    skip_if_not_installed("ape")
    dd <- as.dist(dist(iris[,1:4]))
    x <- dr(dd, ape::pcoa)
    expect_s3_class(x, "DrResult")
    expect_equal(nrow(x$drdata), 150)
})
