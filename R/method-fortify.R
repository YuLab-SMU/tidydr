##' @importFrom ggplot2 fortify
##' @method fortify DrResult
##' @export
fortify.DrResult <- function(model, data, metadata = NULL, ...) {
    res <- model$drdata
    if (is.null(metadata)) return(merge_sample_info(res, model$sample_info))

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

    return(merge_sample_info(res, model$sample_info))
}

## Merge the per-sample elements of a `DrResult`'s `sample_info` slot into `res`.
##
## `sample_info` is documented (see ?dr) as a list of method-specific, per-sample
## information: an element that holds one value per sample becomes a column named
## after the element. Anything else cannot be a column, so it is reported and
## skipped rather than dropped silently; the same holds for a name that is already
## taken, so that coordinates and metadata columns are never overwritten.
## A list whose names are missing, empty or `NA` is not usable as columns at all,
## so it is reported and ignored as a whole.
merge_sample_info <- function(res, sample_info) {
    if (is.null(sample_info) || length(sample_info) == 0L) return(res)

    nms <- names(sample_info)
    ## `nzchar(NA)` is TRUE, so `any(!nzchar(nms))` alone would let an `NA` name
    ## through and produce a column literally named `NA`.
    if (is.null(nms) || anyNA(nms) || any(!nzchar(nms))) {
        warning("'sample_info' must be a named list and was ignored.")
        return(res)
    }

    n <- nrow(res)
    for (i in seq_along(sample_info)) {
        nm <- nms[i]
        val <- sample_info[[i]]

        ## a vector or factor, but not a matrix/data.frame or a list
        if (!(is.atomic(val) && is.null(dim(val)))) {
            warning(sprintf("'sample_info' element '%s' is not a per-sample vector and was not merged.",
                            nm))
            next
        }
        if (length(val) != n) {
            warning(sprintf("'sample_info' element '%s' has length %d, not %d (the number of samples), and was not merged.",
                            nm, length(val), n))
            next
        }
        if (nm %in% colnames(res)) {
            warning(sprintf("'sample_info' element '%s' collides with an existing column and was not merged.",
                            nm))
            next
        }

        col <- data.frame(val)
        colnames(col) <- nm
        res <- cbind(res, col)
    }
    res
}
