##' Dimensional reduction scatter plot axis theme
##'
##'
##' @title theme_dr
##' @param xlength length of x axis
##' @param ylength length of y axis
##' @param arrow arrow specification, as created by 'grid::arrow()'
##' @return a theme object with shorten axes
##' @export
##' @importFrom ggplot2 element_text
##' @importFrom ggplot2 theme_minimal
##' @importFrom ggplot2 %+replace%
##' @importFrom grid arrow
##' @importFrom grid unit
##' @author Guangchuang Yu
theme_dr <- function(xlength = 0.3, ylength=0.3, 
                    arrow = grid::arrow(length=unit(0.15, "inches"), type="closed")
                ) {
    theme_minimal() %+replace% theme_noaxis(
        axis.line.x.bottom=element_line2(id=1, xlength = xlength, arrow = arrow),
        axis.line.y.left=element_line2(id=2, ylength = ylength, arrow = arrow), 
        axis.title=element_text(hjust=0.1))
}

##' theme that remove axis
##'
##'
##' @title theme_noaxis
##' @param ... additional theme setting
##' @return a theme object that disable axes
##' @export
##' @importFrom ggplot2 element_blank
##' @importFrom ggplot2 theme
##' @author Guangchuang Yu
theme_noaxis <- function(...) {
    theme(axis.line=element_blank(), 
        axis.ticks=element_blank(), 
        axis.text=element_blank(),
        ...
    )
}

