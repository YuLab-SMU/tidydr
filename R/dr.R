dr <- function(data, fun, ...) {
    where <- environment(fun = fun) %>%
        rlang::env_name() %>%
        sub(".*:", "", .)

    as.dr(fun, data, where=where, ...)
}

as.dr <- function(fun, data, where, ...) {
    res <- fun(data, ...)
    class(res) <- c(where, class(res))
    drdata <- dr_extract(res)
    colnames(drdata) <- paste0("Dim", seq_along(drdata))
    # minimal information for dimensional reduction
    # need to incorporate more useful info.
    structure(
        list(data = data,
            drdata = drdata,
            .call = match.call(expand.dots=TRUE)
        ),
        class = "DrResult"
    )
}


dr_extract <- function(result) UseMethod("dr_extract")

dr_extract.Rtsne <- function(result) {
    as.data.frame(result$Y)
}

dr_extract.prcomp <- function(result) {
    as.data.frame(result$x)
}

fortify.DrResult <- function(model, data, ...) {
    model$drdata
}

autoplot.DrResult <- function(object, ...) {
    ggplot(object, aes_(~Dim1, ~Dim2)) + geom_point()
}
