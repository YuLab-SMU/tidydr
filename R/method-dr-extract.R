##' dr_extract generic
##' 
##' @title dr_extract
##' @rdname dr-extract
##' @param result DrResult object
##' @return a list that contains components to construct a 'DrResult' object.
##' @details
##' `dr_extract()` is an S3 generic. Methods are provided for the result classes
##' of the supported dimensionality reduction functions. In addition, a fallback
##' method is provided for plain numeric matrices: any function passed to `dr()`
##' that returns a numeric matrix with at least two columns is accepted, and its
##' columns are used as the reduced coordinates.
##'
##' The list returned by a method must contain `drdata`, the reduced coordinates:
##' either a data.frame, or a numeric matrix, with one row per sample and at least
##' two columns (one per retained dimension). A matrix is converted to a
##' data.frame, so that [fortify()] -- a 'ggplot2' generic -- always returns a
##' data.frame. The columns are renamed `Dim1`, `Dim2`, ... by [dr()], and a
##' `drdata` that is neither a data.frame nor a numeric matrix is rejected.
##'
##' `eigenvalue`, `stress` and `sample_info` are optional. `sample_info` is a list
##' of method-specific, per-sample vectors (e.g. local density or cluster labels),
##' which [fortify()] merges into its result as extra columns; see [dr()] for the
##' details.
##' @export
##' @author Guangchuang Yu
dr_extract <- function(result) UseMethod("dr_extract")


##' @method dr_extract Rtsne
#' @export
dr_extract.Rtsne <- function(result) {
    ## Rtsne::Rtsne
    drdata <- as.data.frame(result$Y)
    eigenvalue <- NULL
    stress <- NULL
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract prcomp
#' @export
dr_extract.prcomp <- function(result) {
    ## stats::prcomp
    drdata <- as.data.frame(result$x)
    eigenvalue <- result$sdev
    stress <- NULL
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}


##' @method dr_extract ape
#' @export
dr_extract.ape <- function(result) {
    ## ape::pcoa
    drdata <- as.data.frame(result$vectors)
    stress <- NULL
    eigenvalue <- as.numeric(result$values$Eigenvalues)
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract smacof
#' @export
dr_extract.smacof <- function(result) {
    ## smacof::mds
    drdata <- as.data.frame(result$conf)
    eigenvalue <- NULL
    stress <- result$stress
    stress <- format(stress, digits=4)
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract ecodist
#' @export
dr_extract.ecodist <- function(result) {
    ## ecodist::pco
    drdata <- as.data.frame(result$vectors)
    stress <- NULL
    eigenvalue <- as.numeric(result$values)
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}


##' @method dr_extract ade4
#' @export
dr_extract.ade4 <- function(result) {
    ## ade4::dudi.pco
    drdata <- as.data.frame(result$tab)
    stress <- NULL
    eigenvalue <- as.numeric(result$eig)
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract uwot
## @author Lang Zhou
#' @export
dr_extract.uwot <- function(result) {
    ## uwot::umap
    ## uwot::tumap
    ## uwot::lvish
    drdata <- as.data.frame(result)
    eigenvalue <- stress <- NULL
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract default
#' @export
dr_extract.default <- function(result) {
    drdata <- eigenvalue <- stress <- NULL
    if ("points" %in% names(result)) {
        drdata <- as.data.frame(result$points)
    }
    if ("eig" %in% names(result)) {
        eigenvalue <- as.numeric(result$eig)
    }
    if ("stress" %in% names(result)) {
        stress <- result$stress
        stress <- format(stress, digits=4)
    }
    if (is.null(drdata)) {
        warning("Unable to extract DR coordinates from the result (no 'points' field found); this method may not be directly supported by dr_extract(). See available_methods() or implement a custom dr_extract method for this class.")
    }
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

##' @method dr_extract matrix
#' @export
dr_extract.matrix <- function(result) {
    ## Fallback for methods returning a bare numeric matrix, e.g.
    ## stats::cmdscale() (and any user function that wraps such a method).
    ## Contract: any function passed to dr() that returns a numeric matrix with
    ## at least two columns is accepted; see ?dr_extract.
    if (!is.numeric(result)) {
        stop("dr_extract.matrix() requires a numeric matrix, but a matrix of mode '",
             mode(result), "' was supplied. ",
             "A dimensionality reduction result must contain numeric coordinates.")
    }
    if (ncol(result) < 2) {
        stop(sprintf("dr_extract.matrix() requires a matrix with at least 2 columns (dimensions), but got %d column(s).",
                     ncol(result)))
    }
    drdata <- as.data.frame(result)
    eigenvalue <- stress <- NULL
    list(drdata = drdata, eigenvalue = eigenvalue, stress = stress)
}

## vegan::metaMDS
## no eigenvalue
##' @method dr_extract monoMDS
#' @export
dr_extract.monoMDS <- dr_extract.default
    
## MASS::sammon
##' @method dr_extract MASS
#' @export
dr_extract.MASS <- dr_extract.monoMDS

## vegan::wcmdscale
## no stress
##' @method dr_extract wcmdscale
#' @export
dr_extract.wcmdscale <- dr_extract.default
    
## labdsv::pco
##' @method dr_extract labdsv
#' @export
dr_extract.labdsv <- dr_extract.wcmdscale

