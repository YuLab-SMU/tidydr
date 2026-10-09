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

## ---- F4: no advertised method is left untested ---------------------------

test_that("available_methods() advertises exactly the methods covered by tests", {
    ## The tested set is *derived* from the per-method blocks in
    ## test-dr-extract.R rather than hardcoded.  Deleting a block therefore makes
    ## this test fail, so a claim cannot outlive its evidence; a hardcoded list
    ## would still match after a block had been removed.
    a <- suppressMessages(available_methods("all"))

    src <- readLines(test_path("test-dr-extract.R"))
    ## The title must *end* with `()` -- i.e. be exactly `dr() works for <pkg>::<fn>()`.
    ## Without that anchor the unrelated block "dr() works for stats::cmdscale()
    ## (bare matrix result)" would also yield `stats::cmdscale()`, so deleting the
    ## real per-method block would go unnoticed.
    titles <- grep('^test_that\\("dr\\(\\) works for [^"]*\\(\\)"', src, value = TRUE)
    raw <- unlist(regmatches(
        titles,
        gregexpr("[A-Za-z][A-Za-z0-9.]*::[A-Za-z][A-Za-z0-9._]*\\(\\)", titles)))
    tested <- unique(raw)

    expect_true(length(titles) >= 12)
    ## No advertised method may be supplied by more than one block: a duplicate
    ## would mask the deletion of one of them -- the exact blind spot this test
    ## exists to close.
    expect_false(anyDuplicated(raw) > 0L)
    expect_setequal(tested, a)
    expect_length(a, 14)
    expect_length(tested, 14)

    ## The title-derived set above would still match a *hollowed-out* block (title
    ## kept, assertions stripped), so also require every per-method block to carry
    ## at least one expectation before the next block starts.
    starts <- grep('^test_that\\("dr\\(\\) works for ', src)
    ends <- c(starts[-1L] - 1L, length(src))
    n_expect <- vapply(seq_along(starts), function(i) {
        sum(grepl("expect_", src[starts[i]:ends[i]]))
    }, integer(1))
    expect_true(all(n_expect > 0L))
})

test_that("available_methods() tells the user that methods may need their own arguments", {
    expect_message(available_methods("distance"), "scannf")
    expect_message(available_methods("data"), "check_duplicates")
})

test_that("available_methods('all') prints the shared notes exactly once", {
    ## The notes below the listings are shared by the data and the distance
    ## listing.  Printing them from both branches made them appear twice, so pin
    ## the *count*, not only the presence -- `expect_message()` passes as soon as
    ## one occurrence is seen and would not notice a second one.
    ##
    ## `gregexpr()` returns -1 when nothing matches and `length(-1)` is 1, so
    ## counting the match vector directly would pass vacuously; go through
    ## `regmatches()`, which yields a zero-length result instead.
    captured <- function(method) {
        paste(capture.output(available_methods(method), type = "message"),
              collapse = "\n")
    }
    n_hit <- function(txt, pattern) {
        length(regmatches(txt, gregexpr(pattern, txt))[[1L]])
    }

    all_msg <- captured("all")
    expect_equal(n_hit(all_msg, "any other function that returns"), 1L)
    expect_equal(n_hit(all_msg, "Some methods need their own arguments"), 1L)

    ## the single-listing branches are unchanged: still exactly one note each
    expect_equal(n_hit(captured("data"), "any other function that returns"), 1L)
    expect_equal(n_hit(captured("distance"), "Some methods need their own arguments"), 1L)

    ## the notes must follow both listings, not sit between them
    pos_note <- regexpr("any other function that returns", all_msg)[1L]
    pos_last <- regexpr("ade4::dudi.pco\\(\\)", all_msg)[1L]
    expect_true(pos_last > 0L)
    expect_true(pos_note > pos_last)
})
