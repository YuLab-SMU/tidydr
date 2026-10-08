##' dimensional reduction
##' 
##' This function call the user-provided function ('fun') to 
##' perform dimensional reduction on the input data ('data')
##' @title dr
##' @param data input data
##' @param fun function to perform dimensional reduction
##' @param ... additional parameters passed to 'fun'
##' @return a DrResult object, which contains 'data' (original data), 'drdata' (coordination after dimensionality reduction), eigenvalue (standard deviation explained by each dimension) and stress (evaluate the effect of dimensionality reduction)
##' @importFrom rlang env_name
##' @export
##' @examples
##' x = dr(iris[,1:4], prcomp)
##' autoplot(x, aes(color=.group), metadata=iris$Species)
##' @author Guangchuang Yu
dr <- function(data, fun, ...) {
    validate_dr_data(data)
    where <- env_name(environment(fun = fun))
    where <- sub(".*:", "", where)
    as.dr(fun, data, where=where, ...)
}

## Internal input contract check for `dr()`.
## Not exported: it exists to fail fast with a tidydr-flavoured message
## instead of leaking an obscure error from the downstream method.
##
## Accepted inputs: numeric matrix, numeric data.frame, and 'dist' objects.
## Note that `is.vector(as.dist(x))` and `is.matrix(as.dist(x))` are both FALSE,
## so 'dist' objects must be recognised explicitly (via `inherits()`).
validate_dr_data <- function(data) {
    if (is.null(data)) {
        stop("`dr()`: 'data' must not be NULL. ",
             "Please supply a numeric matrix, a numeric data.frame, ",
             "or a distance object (see `as.dist()`).", call. = FALSE)
    }

    if (inherits(data, "dist")) {
        check_finite_dr_data(data)
        return(invisible(TRUE))
    }

    if (is.data.frame(data)) {
        if (ncol(data) < 1) {
            stop("`dr()`: 'data' must have at least one column.", call. = FALSE)
        }
        num <- vapply(data, is.numeric, logical(1))
        if (!all(num)) {
            stop("`dr()`: all columns of 'data' must be numeric. ",
                 "Non-numeric column(s): ", paste(names(data)[!num], collapse = ", "), ". ",
                 "Please select the numeric columns (e.g. `iris[, 1:4]`) ",
                 "or encode them numerically before calling `dr()`.",
                 call. = FALSE)
        }
        check_finite_dr_data(data)
        return(invisible(TRUE))
    }

    if (is.matrix(data)) {
        if (!is.numeric(data)) {
            stop("`dr()`: 'data' must be a numeric matrix, but a matrix of mode '",
                 mode(data), "' was supplied.", call. = FALSE)
        }
        if (ncol(data) < 1) {
            stop("`dr()`: 'data' must have at least one column.", call. = FALSE)
        }
        check_finite_dr_data(data)
        return(invisible(TRUE))
    }

    if (is.vector(data) && is.atomic(data)) {
        hint <- if (is.numeric(data)) {
            paste0("If 'data' is a vector of distances, convert it with `as.dist()`; ",
                   "otherwise, provide a numeric matrix or data.frame ",
                   "for dimensionality reduction.")
        } else {
            "Please provide a numeric matrix or data.frame for dimensionality reduction."
        }
        stop("`dr()`: 'data' must be a matrix, data.frame or 'dist' object, ",
             "not a bare vector. ", hint, call. = FALSE)
    }

    stop("`dr()`: unsupported 'data' type (",
         paste(class(data), collapse = "/"), "). ",
         "Please supply a numeric matrix, a numeric data.frame, ",
         "or a distance object (see `as.dist()`).", call. = FALSE)
}

## Reject missing / non-finite values early, with a message that tells the
## user what to do instead of forwarding e.g. prcomp's "infinite or missing
## values in 'x'".  Handles data.frame column-by-column to avoid a full copy.
check_finite_dr_data <- function(data) {
    if (is.data.frame(data)) {
        ok <- vapply(data, function(x) !anyNA(x) && all(is.finite(x)), logical(1))
    } else {
        ok <- !anyNA(data) && all(is.finite(data))
    }
    if (!all(ok)) {
        stop("`dr()`: 'data' contains missing (NA/NaN) or infinite (Inf) values. ",
             "Please handle missing values (e.g. impute or drop them) ",
             "before calling `dr()`.", call. = FALSE)
    }
    invisible(TRUE)
}

as.dr <- function(fun, data, where, ...) {
    res <- fun(data, ...)
    class(res) <- c(where, class(res))
    dr_result <- dr_extract(res)
    drdata <- dr_result$drdata
    if (is.null(drdata)) {
        stop("dr_extract() could not extract DR coordinates from the result of 'fun'. ",
             "This method may not be supported. See available_methods() for supported methods, ",
             "or implement a custom dr_extract method for this result class.")
    }
    colnames(drdata) <- paste0("Dim", seq_along(drdata))
    eigenvalue <- dr_result$eigenvalue
    stress <- dr_result$stress
    # minimal information for dimensional reduction
    # need to incorporate more useful info.
    structure(
        list(data = data,
            drdata = drdata,
            eigenvalue = eigenvalue,
            stress = stress,
            .call = match.call(expand.dots=TRUE)
        ),
        class = "DrResult"
    )
}

##' @method print DrResult
##' @importFrom utils head
##' @export
print.DrResult <- function (x, ...) {
    if (!is.null(x$eigenvalue)) {
        cat(sprintf("Eigen value (1, .., p=%d):\n", length(x$eigenvalue)))
        print(x$eigenvalue, ...)
    }
    if (!is.null(x$stress)) {
        cat(sprintf("Stress: %s\n", x$stress))
    }
    d <- dim(x$drdata)
    cat(sprintf("\nDimensionality reduction (n x k) = (%d x %d):\n", d[1], d[2]))
    print(head(x$drdata), ...)

    invisible(x)
}
