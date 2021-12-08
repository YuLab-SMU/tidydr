##' element_line2 for drawing shorten axis lines 
##'
##' @title element_line2
##' @param colour line colour
##' @param size line size in pts
##' @param linetype line type
##' @param lineend line end style (round, butt, square)
##' @param color aliase to colour
##' @param arrow arrow specification, as created by 'grid::arrow()'
##' @param inherit.blank whether inherit 'element_blank'
##' @param id 1 or 2, 1 for axis.line.x.bottom and 2 for axis.line.y.left, only these two axes supported
##' @param xlength length of x axis
##' @param ylength length of y axis
##' @param ... additional parameters
##' @return element_line2 object, which is a tailored element_line object
##' @export
##' @author Guangchuang Yu
element_line2 <- function (colour = NULL, size = NULL, linetype = NULL, lineend = NULL, 
    color = NULL, arrow = NULL, inherit.blank = FALSE, id, xlength=0.3, ylength=0.3, ...) {
    if (!is.null(color)) 
        colour <- color
    if (is.null(arrow)) 
        arrow <- FALSE
    structure(list(colour = colour, size = size, linetype = linetype, 
        lineend = lineend, arrow = arrow, inherit.blank = inherit.blank, 
        id = id, xlength = xlength, ylength = ylength,
        ...), 
        class = c("element_line2", "element_line", "element"))
}

##' @importFrom ggplot2 element_grob
##' @importFrom grid gpar
##' @importFrom grid grob
##' @method element_grob element_line2
##' @export
element_grob.element_line2 <- function (element, colour = NULL, size = NULL, 
    linetype = NULL, lineend = NULL, default.units = "npc", id.lengths = NULL, 
    ...) {

    gp <- gpar(col = colour, fill = colour, lwd = len0_null(size * 
        .pt), lty = linetype, lineend = lineend)
    element_gp <- gpar(col = element$colour, fill = element$colour, 
        lwd = len0_null(element$size * .pt), lty = element$linetype, 
        lineend = element$lineend)

    grob(default.units = default.units, 
        gp = modify_list(element_gp, gp), 
        arrow = element$arrow, id=element$id, 
        xlength = element$xlength,
        ylength = element$ylength, 
        cl="draxis")   

}


