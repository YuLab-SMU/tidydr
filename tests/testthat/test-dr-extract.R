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
