#' Generate Sequence for Tasks without Similar Response
#'
#' @title generate_seq
#' @return
#' @author Liang Zhang
#' @export
generate_seq_post <- function() {
  n_block <- 2L
  expand_grid(
    stim = 1:90,
    stim_type = c("word", "object", "place", "face")
  ) |>
    mutate(cresp = if_else(stim > 45L, "new", "old")) |>
    slice_sample(prop = 1L) |>
    add_column(run_id = 1L, .before = 1L) |>
    # cut into two blocks
    mutate(
      block_id = rep(seq_len(n_block), each = n() / n_block),
      trial_id = rep(seq_len(n() / n_block), times = n_block),
      .after = run_id
    )
}
