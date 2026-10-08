test_that("available_methods returns character vectors", {
    d <- suppressMessages(available_methods("data"))
    m <- suppressMessages(available_methods("distance"))
    a <- suppressMessages(available_methods("all"))
    expect_type(d, "character")
    expect_type(m, "character")
    expect_type(a, "character")
    expect_equal(length(a), length(d) + length(m))
    expect_true("stats::prcomp()" %in% d)
    expect_true("vegan::metaMDS()" %in% m)
})

test_that("available_methods errors on invalid method", {
    expect_error(available_methods("foo"), "'arg' should be one of")
})

test_that("available_methods advertises the numeric-matrix contract", {
    expect_message(available_methods("distance"), "numeric matrix")
    expect_message(available_methods("data"), "numeric matrix")
})
