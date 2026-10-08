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
