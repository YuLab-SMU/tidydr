##' @importFrom ggplot2 fortify
##' @method fortify DrResult
##' @export
fortify.DrResult <- function(model, data, ...) {
    model$drdata
}

