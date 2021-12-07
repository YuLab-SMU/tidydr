##' @importFrom ggplot2 fortify
##' @method fortify DrResult
##' @export
fortify.DrResult <- function(model, data, metadata = NULL, ...) {
    res <- model$drdata
    if (is.null(metadata)) return(res)

    msg <- paste0('the length of metadata is not consistent with the input data',
                '\n\tand metadata will be ignored')
    if (is.vector(metadata) || is.factor(metadata)) {
        if (length(metadata) != nrow(res)) {
            warning(msg)
        } else {
            res <- cbind(res, .group=metadata)
        }
    }    

    if (is.data.frame(metadata)) {
        if (nrow(metadata) != nrow(res)) {
            warning(msg)
        } else {
            res <- cbind(res, metadata)
        }
    }

    return(res)
}


