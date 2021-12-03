##' dr_extract generic
##' 
##' @title dr_extract
##' @rdname dr-extract
##' @param result DrResult object
##' @return data frame
##' @export
##' @author Guangchuang Yu
dr_extract <- function(result) UseMethod("dr_extract")

##' @method dr_extract Rtsne
dr_extract.Rtsne <- function(result) {
    as.data.frame(result$Y)
}

##' @method dr_extract prcomp
dr_extract.prcomp <- function(result) {
    as.data.frame(result$x)
}

