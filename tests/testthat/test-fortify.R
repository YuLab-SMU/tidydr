test_that("fortify returns the coordinates unchanged when metadata is NULL", {
    x <- dr(iris[,1:4], prcomp)
    f <- fortify(x)
    expect_equal(ncol(f), 4)
    expect_equal(colnames(f), paste0("Dim", 1:4))
})

test_that("fortify keeps the '.group' behaviour for vector metadata", {
    x <- dr(iris[,1:4], prcomp)
    f <- fortify(x, metadata = iris$Species)
    expect_equal(ncol(f), 5)
    expect_true(".group" %in% colnames(f))
    expect_equal(f$.group, iris$Species)
})

test_that("fortify keeps the '.group' behaviour for factor metadata", {
    x <- dr(iris[,1:4], prcomp)
    f <- fortify(x, metadata = factor(iris$Species))
    expect_equal(ncol(f), 5)
    expect_true(".group" %in% colnames(f))
    expect_true(is.factor(f$.group))
})

test_that("fortify warns when vector metadata length does not match", {
    x <- dr(iris[,1:4], prcomp)
    expect_warning(f <- fortify(x, metadata = 1:10), "not consistent")
    expect_equal(ncol(f), 4)
})

test_that("fortify cbind()-s data.frame metadata when rows match", {
    x <- dr(iris[,1:4], prcomp)
    md <- data.frame(grp = iris$Species, id = seq_len(150))
    f <- fortify(x, metadata = md)
    expect_equal(ncol(f), 6)
    expect_true(all(c("grp", "id") %in% colnames(f)))
})

test_that("fortify warns when data.frame metadata rows do not match", {
    x <- dr(iris[,1:4], prcomp)
    expect_warning(f <- fortify(x, metadata = data.frame(grp = 1:5)),
                   "not consistent")
    expect_equal(ncol(f), 4)
})

## ---- U3: metadata type handling -----------------------------------------

test_that("fortify no longer silently drops matrix metadata", {
    x <- dr(iris[,1:4], prcomp)
    md <- matrix(1:300, nrow = 150)
    f <- fortify(x, metadata = md)
    expect_equal(nrow(f), 150)
    expect_equal(ncol(f), 6)
    expect_false(any(grepl("^\\.group\\.", colnames(f))))
})

test_that("fortify warns when matrix metadata rows do not match", {
    x <- dr(iris[,1:4], prcomp)
    expect_warning(f <- fortify(x, metadata = matrix(1:10, nrow = 5)),
                   "not consistent")
    expect_equal(ncol(f), 4)
})

test_that("fortify warns and ignores list metadata (no junk columns)", {
    x <- dr(iris[,1:4], prcomp)
    expect_warning(f <- fortify(x, metadata = as.list(1:150)),
                   "not supported")
    expect_equal(ncol(f), 4)
    expect_false(any(grepl("^\\.group\\.", colnames(f))))
})

test_that("fortify warns and ignores other unsupported metadata", {
    x <- dr(iris[,1:4], prcomp)
    expect_warning(f <- fortify(x, metadata = array(1:8, dim = c(2, 2, 2))),
                   "not supported")
    expect_equal(ncol(f), 4)
})
