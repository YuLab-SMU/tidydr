##' @importFrom ggplot2 fortify
##' @method fortify DrResult
##' @export
fortify.DrResult <- function(model, data, metadata = NULL, ...) {
    res <- model$drdata
    if (is.null(metadata)) return(res)

    msg <- paste0('the length of metadata is not consistent with the input data',
                '\n\tand metadata will be ignored')

    ## a matrix is a legitimate way to pass several metadata columns;
    ## handle it through the data.frame path rather than dropping it silently.
    if (is.matrix(metadata)) {
        metadata <- as.data.frame(metadata)
    }

    if (is.factor(metadata) ||
        (is.atomic(metadata) && is.null(dim(metadata)))) {
        ## NOTE: `is.vector()` returns TRUE for a plain list, so a list must be
        ## excluded explicitly (otherwise it is cbind()-ed into n junk columns).
        if (length(metadata) != nrow(res)) {
            warning(msg)
        } else {
            res <- cbind(res, .group=metadata)
        }
    } else if (is.data.frame(metadata)) {
        if (nrow(metadata) != nrow(res)) {
            warning(msg)
        } else {
            res <- cbind(res, metadata)
        }
    } else {
        warning(paste0("metadata of class '", paste(class(metadata), collapse = "/"),
                       "' is not supported and will be ignored.\n\t",
                       "Supported types: vector, factor, matrix, data.frame."))
    }

    return(res)
}
