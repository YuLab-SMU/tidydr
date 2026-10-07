##' Choose best K (number of clusters)
##' 
##' This function calculate the silhouette scores of each K (number of clusters). 
##' The output object can be used to choose the best K (via `summary()` or `autoplot()` methods)
##' @title nk
##' @param data input data (a matrix or data frame)
##' @param k a vector of candidate number of clusters
##'
##' Note: this function calls `cluster::pam()` once for each candidate k, and `pam()` has O(n^2) time and memory complexity in the number of samples. For large datasets (e.g., thousands of cells/samples), this can be slow or memory-intensive. Consider subsampling the data or reducing the range of k for exploratory use.
##' @return a `silinfo` object, which contains 'data' (original data), 'silinfo' (silhouette scores), and k (the input k vector)
##' @importFrom cluster pam
##' @export
##' @examples
##' x <- nk(iris[,-5], 2:8)
##' summary(x)
##' # to visualize the average silhouete score (y axis) with k (x axis)
##' autoplot(x)
##' # to visualize a PCA plot color by the choosing k
##' autoplot(x, k=3)
##' @author Guangchuang Yu
nk <- function(data, k) {
    y = lapply(k, function(i) {
        x <- pam(data, k=i)
        x$silinfo
    })
    structure(list(data = data,
                silinfo = y, 
                k=k),
        class = "silinfo"
    )
}

##' @method print silinfo
##' @export
print.silinfo <- function(x, ...) {
    y <- summary(x)
    best <- which.max(y[,2])
    k <- y[best, 1]
    avg.width <- y[best, 2]

    msg <- c(
        sprintf("Silhouette information for K = %s", paste0(range(x$k), collapse=":")),
        sprintf("Best K (number of clusters) is %s (average silhouette width: %.3f)", k, avg.width)
        )
    if (avg.width < 0.25) {
        msg <- c(msg, "Note: the silhouette width is relatively low, suggesting the clustering structure may be weak.")
    }
    cat(msg, sep = "\n")
}

##' @method summary silinfo
##' @export
summary.silinfo <- function(object, ...) {
    K <- object$k
    y <- vapply(object$silinfo, function(x) {
            x$avg.width
        }, FUN.VALUE = numeric(1))

    res <- data.frame(K=K, 
            Silhouette = y)
    return(res)
}

