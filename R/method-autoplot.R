##' @importFrom ggplot2 autoplot
##' @export
ggplot2::autoplot

##' @importFrom ggplot2 autoplot
##' @method autoplot DrResult
##' @importFrom ggplot2 ggplot
##' @importFrom ggplot2 geom_point
##' @importFrom ggplot2 aes_
##' @export
autoplot.DrResult <- function(object, ...) {
    ggplot(object, aes_(~Dim1, ~Dim2)) + geom_point()
}

