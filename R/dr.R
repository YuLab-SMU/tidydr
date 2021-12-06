##' dimensional reduction
##' 
##' This function call the user-provided function ('fun') to 
##' perform dimensional reduction on the input data ('data')
##' @title dr
##' @param data input data
##' @param fun function to perform dimensional reduction
##' @param ... additional parameters passed to 'fun'
##' @return DrResult object
##' @importFrom rlang env_name
##' @export
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

