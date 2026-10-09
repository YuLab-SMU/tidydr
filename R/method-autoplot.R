##' @importFrom ggplot2 autoplot
##' @export
ggplot2::autoplot

##' @importFrom ggplot2 facet_grid
##' @importFrom ggplot2 geom_col
##' @importFrom ggplot2 geom_hline
##' @importFrom ggplot2 geom_line
##' @importFrom ggplot2 geom_point
##' @importFrom stats prcomp
##' @method autoplot silinfo
##' @export
autoplot.silinfo <- function(object, k=NULL, type=NULL, ...) {
    ## keep the historical behaviour: without `k` show the average silhouette
    ## width against k, with `k` show a PCA coloured by cluster
    if (is.null(type)) {
        type <- if (is.null(k)) "k" else "pca"
    }
    type <- match.arg(type, c("k", "pca", "silhouette"))

    if (type == "k") {
        K <- Silhouette <- NULL
        
        x <- summary(object)
        p <- ggplot(x, aes(K, Silhouette)) + 
            geom_line(linetype='dashed') + 
            geom_point(size=3, color='steelblue') +
            theme_minimal()
        return(p)
    }

    if (is.null(k)) {
        stop(sprintf("`autoplot()`: 'k' must be provided for type = \"%s\".", type))
    }
    if (!k %in% object$k) {
        stop(sprintf("k = %s is not among the candidate k values used in nk(): %s",
                     k, paste(object$k, collapse = ", ")))
    }
    if (type == "silhouette") {
        return(autoplot_silinfo_bar(object, k))
    }

    PC1 <- PC2 <- cluster <- NULL

    pca <- prcomp(object$data)
    d <- as.data.frame(pca$x)
    ## `pam()` returns `widths` ordered by cluster and by decreasing silhouette
    ## width, so it must be aligned to the PCA scores by sample name rather than
    ## by position.
    d$cluster <- silinfo_cluster_labels(object, k, rownames(d))
    ggplot(d, aes(PC1, PC2)) + 
        geom_point(aes(color=cluster)) +
        theme_minimal()
}

## Cluster labels of `k`, aligned to the rows of the input data.
##
## `cluster::pam()` returns `silinfo$widths` ordered by cluster and, within a
## cluster, by decreasing silhouette width, so its rows do not line up with the
## input data. The labels are therefore matched by sample name. If the names are
## missing or do not match one-to-one, the historical positional behaviour is
## kept rather than failing.
silinfo_cluster_labels <- function(object, k, rn) {
    w <- object$silinfo[[which(object$k == k)[1L]]]$widths
    cl <- w[, "cluster"]
    rn_w <- rownames(w)
    if (!is.null(rn_w) && !is.null(rn) &&
        length(rn_w) == length(rn) && !anyDuplicated(rn_w) &&
        all(rn %in% rn_w)) {
        cl <- cl[match(rn, rn_w)]
    }
    factor(cl)
}

## The classic silhouette bar plot: one panel per cluster, samples ordered by
## decreasing silhouette width within each panel.
autoplot_silinfo_bar <- function(object, k) {
    sample <- sil_width <- cluster <- NULL

    w <- silinfo_widths(object, k)
    w <- w[order(w$cluster, -w$sil_width), , drop = FALSE]
    w$sample <- factor(w$sample, levels = w$sample)
    w$cluster <- factor(w$cluster)

    ggplot(w, aes(x = sample, y = sil_width)) +
        geom_col(aes(fill = cluster), width = 1) +
        geom_hline(yintercept = 0, colour = "grey30") +
        geom_hline(yintercept = mean(w$sil_width), linetype = "dashed",
                   colour = "grey30") +
        facet_grid(~ cluster, scales = "free_x", space = "free_x") +
        theme_minimal() +
        theme(axis.text.x = element_blank(),
              axis.ticks.x = element_blank()) +
        xlab("") +
        ylab("Silhouette width")
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

