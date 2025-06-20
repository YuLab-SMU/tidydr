len0_null <- function(x) {
  if (length(x) == 0) {
    NULL
  } else {
    x
  }
}
modify_list <- function(old, new) {
  for (i in names(new)) old[[i]] <- new[[i]]
  old
}
.pt <- ggplot2::.pt


##' @importFrom ggplot2 aes
##' @export
ggplot2::aes
