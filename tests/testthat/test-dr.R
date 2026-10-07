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
