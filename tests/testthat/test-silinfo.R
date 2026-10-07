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
