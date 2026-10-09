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

## ---- F3: DrResult 'sample_info' slot -------------------------------------------

test_that("dr() records an 'sample_info' slot, NULL by default", {
    x <- dr(iris[,1:4], prcomp)
    expect_true("sample_info" %in% names(x))
    expect_null(x$sample_info)
})

test_that("as.dr() carries the 'sample_info' element returned by a dr_extract method", {
    ## a test-only dr_extract method; S3 dispatch from inside the package
    ## namespace only sees methods registered there, not methods defined at the
    ## top level of a test file.
    registerS3method("dr_extract", "tidydr_sample_info_probe",
                     function(result) {
                         list(drdata = as.data.frame(result$points),
                              eigenvalue = NULL,
                              stress = NULL,
                              sample_info = result$sample_info)
                     },
                     envir = asNamespace("tidydr"))

    f <- function(d, ...) {
        structure(list(points = stats::prcomp(d)$x,
                       sample_info = list(foo = seq_len(nrow(d)))),
                  class = "tidydr_sample_info_probe")
    }

    x <- dr(iris[,1:4], f)
    expect_s3_class(x, "DrResult")
    expect_equal(nrow(x$drdata), 150)
    expect_equal(x$sample_info$foo, seq_len(150))
})

test_that("print.DrResult output is unchanged by a non-empty 'sample_info'", {
    with_sample_info <- dr(iris[,1:4], prcomp)
    with_sample_info$sample_info <- list(grp = iris$Species, dens = seq_len(150))
    plain <- dr(iris[,1:4], prcomp)

    expect_identical(capture.output(print(with_sample_info)),
                     capture.output(print(plain)))
    expect_false(any(grepl("sample_info", capture.output(print(with_sample_info)))))
})

## ---- dr_extract() may return the coordinates as a plain numeric matrix ------

test_that("a dr_extract() method may return 'drdata' as a numeric matrix", {
    ## `drdata` is a data.frame on every path shipped with the package, but a
    ## hand-written method may return a bare matrix. That used to fail with
    ## "length of 'dimnames' [2] not equal to array extent", because the slot was
    ## named with `seq_along(drdata)` -- which counts *elements* on a matrix.
    registerS3method("dr_extract", "tidydr_matrix_probe",
                     function(result) list(drdata = result$pts),
                     envir = asNamespace("tidydr"))

    f <- function(d, ...) {
        structure(list(pts = stats::cmdscale(stats::dist(d), k = 2)),
                  class = "tidydr_matrix_probe")
    }

    x <- dr(iris[,1:4], f)
    expect_s3_class(x, "DrResult")
    ## normalised to a data.frame, so that fortify() (a ggplot2 generic, which
    ## must return a data.frame) never hands a matrix to ggplot()
    expect_s3_class(x$drdata, "data.frame")
    expect_equal(colnames(x$drdata), c("Dim1", "Dim2"))
    expect_equal(dim(x$drdata), c(150L, 2L))
    expect_s3_class(fortify(x), "data.frame")
})

test_that("a dr_extract() method returning neither a data.frame nor a matrix is rejected", {
    registerS3method("dr_extract", "tidydr_vector_probe",
                     function(result) list(drdata = seq_len(150)),
                     envir = asNamespace("tidydr"))

    f <- function(d, ...) structure(list(pts = d), class = "tidydr_vector_probe")

    expect_error(dr(iris[,1:4], f),
                 "must return 'drdata' as a data.frame or a numeric matrix")
})
