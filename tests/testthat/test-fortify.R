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

## ---- F3: 'sample_info' slot ----------------------------------------------------

dr_with_sample_info <- function(sample_info) {
    x <- dr(iris[,1:4], prcomp)
    x$sample_info <- sample_info
    x
}

test_that("fortify with a NULL 'sample_info' behaves exactly as before", {
    x <- dr(iris[,1:4], prcomp)
    expect_null(x$sample_info)
    expect_equal(fortify(x), x$drdata)
    f <- fortify(x, metadata = iris$Species)
    expect_equal(colnames(f), c("Dim1", "Dim2", "Dim3", "Dim4", ".group"))
})

test_that("fortify merges per-sample 'sample_info' elements as columns", {
    x <- dr_with_sample_info(list(grp = iris$Species, dens = seq_len(150)))
    f <- fortify(x)
    expect_equal(ncol(f), 6)
    expect_true(all(c("grp", "dens") %in% colnames(f)))
    expect_equal(f$grp, iris$Species)
    expect_equal(f$dens, seq_len(150))
    ## the coordinates themselves are untouched
    expect_equal(f$Dim1, x$drdata$Dim1)
})

test_that("fortify merges 'sample_info' together with metadata", {
    x <- dr_with_sample_info(list(dens = seq_len(150)))
    f <- fortify(x, metadata = iris$Species)
    expect_equal(colnames(f),
                 c("Dim1", "Dim2", "Dim3", "Dim4", ".group", "dens"))
    expect_equal(f$.group, iris$Species)
    expect_equal(f$dens, seq_len(150))
})

test_that("fortify warns and skips an 'sample_info' element of the wrong length", {
    x <- dr_with_sample_info(list(bad = 1:3, good = seq_len(150)))
    expect_warning(f <- fortify(x), "has length 3")
    expect_equal(ncol(f), 5)
    expect_false("bad" %in% colnames(f))
    expect_true("good" %in% colnames(f))
})

test_that("fortify warns and skips a non-per-sample 'sample_info' element", {
    x <- dr_with_sample_info(list(mat = matrix(1:300, nrow = 150),
                            good = seq_len(150)))
    expect_warning(f <- fortify(x), "not a per-sample vector")
    expect_equal(ncol(f), 5)
    expect_false("mat" %in% colnames(f))
    expect_true("good" %in% colnames(f))
})

test_that("fortify warns and skips a list 'sample_info' element", {
    x <- dr_with_sample_info(list(lst = as.list(seq_len(150)), good = seq_len(150)))
    expect_warning(f <- fortify(x), "not a per-sample vector")
    expect_equal(ncol(f), 5)
    expect_false("lst" %in% colnames(f))
})

test_that("fortify warns and skips an 'sample_info' element colliding with a coordinate", {
    x <- dr_with_sample_info(list(Dim1 = seq_len(150), good = seq_len(150)))
    expect_warning(f <- fortify(x), "collides")
    expect_equal(ncol(f), 5)
    expect_equal(f$Dim1, x$drdata$Dim1)   # the coordinate is not overwritten
    expect_true("good" %in% colnames(f))
})

test_that("fortify warns and skips an 'sample_info' element colliding with metadata", {
    x <- dr_with_sample_info(list(.group = seq_len(150)))
    expect_warning(f <- fortify(x, metadata = iris$Species), "collides")
    expect_equal(f$.group, iris$Species)
})

test_that("fortify ignores an unnamed 'sample_info' list with a warning", {
    x <- dr_with_sample_info(list(seq_len(150)))
    expect_warning(f <- fortify(x), "must be a named list")
    expect_equal(ncol(f), 4)
})

test_that("fortify ignores an 'sample_info' list with NA or empty names", {
    ## `nzchar(NA)` is TRUE, so an NA name must be caught explicitly; otherwise
    ## it slips through and cbind() creates a column literally named `NA`
    x <- dr_with_sample_info(structure(list(seq_len(150)), names = NA_character_))
    expect_warning(f <- fortify(x), "must be a named list")
    expect_equal(ncol(f), 4)
    expect_false(anyNA(colnames(f)))

    x <- dr_with_sample_info(structure(list(seq_len(150)), names = ""))
    expect_warning(f <- fortify(x), "must be a named list")
    expect_equal(ncol(f), 4)

    ## a partially-NA name vector is rejected as a whole, so the good element
    ## is not merged either
    x <- dr_with_sample_info(structure(list(seq_len(150), seq_len(150)),
                                 names = c("good", NA_character_)))
    expect_warning(f <- fortify(x), "must be a named list")
    expect_equal(ncol(f), 4)
})

test_that("autoplot works with a non-empty 'sample_info' slot", {
    x <- dr_with_sample_info(list(dens = seq_len(150)))
    expect_s3_class(autoplot(x), "ggplot")
    p <- autoplot(x, aes(color = dens))
    expect_s3_class(p, "ggplot")
    expect_equal(p$data$dens, seq_len(150))
})
