##' This function shows available methods that worked for `dr()` function.
##' 
##' @title List dimensionality reduction methods currently available
##' @param method one of 'data', 'distance' or 'all' (default)
##' @return A character vector of available DR methods
##' @examples available_methods()
##' @export
##' @author Lang Zhou and Guangchuang Yu
available_methods <- function(method = "all") {
    method <- match.arg(method,  c("all", "data", "distance"))
    data_methods <- c("stats::prcomp()",
                      "Rtsne::Rtsne()",
                      "uwot::umap()",
                      "uwot::tumap()",
                      "uwot::lvish()")
    
    distance_methods <- c("stats::cmdscale()",
                          "MASS::sammon()",
                          "vegan::metaMDS()",
                          "ape::pcoa()",
                          "smacof::mds()",
                          "vegan::wcmdscale()",
                          "ecodist::pco()",
                          "labdsv::pco()",
                          "ade4::dudi.pco()")
 
    msg_data <- c("The `dr()` function works for the following methods that\n",
                  "require data matrix (or data frame) as input:\n",
                  paste("  + ", data_methods, collapse = "\n"))

    msg_distance <- c("The `dr()` function works for the following methods that\n",
                      "require distance matrix (or distance object) as input:\n",
                      paste("  + ", distance_methods, collapse = "\n"))

    if (method == "all") {
        message(msg_data, "\n")
        message(msg_distance)
        invisible(c(data_methods, distance_methods))
    } else if (method == "data") {
        message(msg_data)
        invisible(data_methods)
    } else {
        message(msg_distance)
        invisible(distance_methods)
    }
}



