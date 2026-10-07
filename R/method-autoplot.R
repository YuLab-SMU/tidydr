##' @importFrom ggplot2 autoplot
##' @export
ggplot2::autoplot

##' @importFrom ggplot2 geom_line
##' @importFrom ggplot2 geom_point
##' @importFrom stats prcomp
##' @method autoplot silinfo
##' @export
autoplot.silinfo <- function(object, k=NULL, ...) {
    if (is.null(k)) {
        K <- Silhouette <- NULL
        
        x <- summary(object)
        p <- ggplot(x, aes(K, Silhouette)) + 
            geom_line(linetype='dashed') + 
            geom_point(size=3, color='steelblue') +
            theme_minimal()
        return(p)
    }

    PC1 <- PC2 <- cluster <- NULL

    if (!k %in% object$k) {
        stop(sprintf("k = %s is not among the candidate k values used in nk(): %s",
                     k, paste(object$k, collapse = ", ")))
    }
    pca <- prcomp(object$data)
    d <- as.data.frame(pca$x)
    d$cluster <- factor(object$silinfo[object$k == k][[1]]$widths[, "cluster"])
    ggplot(d, aes(PC1, PC2)) + 
        geom_point(aes(color=cluster)) +
        theme_minimal()
}

##' @importFrom ggplot2 autoplot
##' @method autoplot DrResult
##' @importFrom ggplot2 ggplot
##' @importFrom ggplot2 geom_point
##' @importFrom utils modifyList
##' @export
autoplot.DrResult <- function(object, mapping, metadata = NULL, ...) {
    Dim1 <- Dim2 <- NULL

    if (missing(mapping) || is.null(mapping)) {
        mapping <- aes(x = Dim1, y = Dim2)
    }else {
        mapping <- modifyList(aes(x = Dim1, y = Dim2), mapping)
    }
    ggplot(object, mapping, metadata=metadata) + geom_point(...)
}

##' @importFrom ggfun get_aes_var
##' @importFrom ggplot2 xlab
##' @importFrom ggplot2 ylab
##' @importFrom rlang .data
##' @method autoplot SingleCellExperiment
##' @export
autoplot.SingleCellExperiment <- function(object, mapping = NULL, 
                    dim = 1:2, dimred="UMAP", 
                    marker = NULL, .fun=NULL, ...) {
    red_dim <- as.matrix(SingleCellExperiment::reducedDim(object, dimred))
    d <- data.frame(red_dim[, dim]) # currently suppose of length 2
    colnames(d) <- c("Dim1", "Dim2")
    lb <- paste(dimred, dim)

    if (!is.null(mapping)) {
        nm <- names(mapping)
        nm <- nm[!nm %in% c("x", "y")]
        if (!is.null(marker)) {
            nm <- nm[nm != 'colour']
        }
        if (length(nm) > 0) {
            vars <- vapply(nm, function(i) get_aes_var(mapping, i), 'character')
            d2 <- SummarizedExperiment::colData(object)[vars]
            d <- cbind(d, d2)
        }
    }

    if (!is.null(marker)) {
        # use marker gene to color the plot
        if (length(marker) != 1) {
            message("Please only pass 1 marker gene to color the plot\n")
            # just ignore it
        } else {
            expr_type <- get_aes_var(mapping, "colour") # logcounts
            mapping <- modifyList(mapping, aes(colour = .data[[marker]]))

            expr_val <- SummarizedExperiment::assay(object, expr_type)[marker, ] # eg STMN1
            if (is.null(.fun)) {
                d[[marker]] <- expr_val
            } else {
                d[[marker]] <- .fun(expr_val)
            }
        }
    }
    autoplot.DrResult(d, mapping, ...) + 
        theme_dr() +
        xlab(lb[1]) +
        ylab(lb[2])
}

