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
    where <- env_name(environment(fun = fun))
    where <- sub(".*:", "", where)
    as.dr(fun, data, where=where, ...)
}

as.dr <- function(fun, data, where, ...) {
    res <- fun(data, ...)
    class(res) <- c(where, class(res))
    dr_result <- dr_extract(res)
    drdata <- dr_result$drdata
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
        cat(sprintf("Stress: %d\n"), x$stress)
    }
    d <- dim(x$drdata)
    cat(sprintf("\nDimensionality reduction (n x k) = (%d x %d):\n", d[1], d[2]))
    print(head(x$drdata), ...)

    invisible(x)
}
