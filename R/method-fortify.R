##' @importFrom ggplot2 fortify
##' @method fortify DrResult
fortify.DrResult <- function(model, data, ...) {
    model$drdata
}

