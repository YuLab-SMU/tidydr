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

    msg_note <- c("\n\nNote: any other function that returns a numeric matrix with\n",
                  "at least two columns is also accepted (see `?dr_extract`).\n",
                  "Some methods need their own arguments, which are passed through\n",
                  "`...` of `dr()`, e.g. `dr(d, ade4::dudi.pco, scannf = FALSE)` or\n",
                  "`dr(x, Rtsne::Rtsne, check_duplicates = FALSE)`.")

    if (method == "all") {
        ## `msg_note` is shared by the data and the distance listing, so it is
        ## printed once at the end rather than once per listing.
        message(msg_data, "\n")
        message(msg_distance, msg_note)
        invisible(c(data_methods, distance_methods))
    } else if (method == "data") {
        message(msg_data, msg_note)
        invisible(data_methods)
    } else {
        message(msg_distance, msg_note)
        invisible(distance_methods)
    }
}



