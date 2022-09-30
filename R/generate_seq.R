#' Generate Sequence for Tasks without Similar Response
#'
#' @title generate_seq
#' @return
#' @author Liang Zhang
#' @export
generate_seq_post <- function() {
  set.seed(1)
  stim_types <- c("word", "object", "place", "face")
  stim_pool <- bind_rows(
    expand_grid(
      stim = 1:45,
      stim_type = stim_types,
      cresp = c("old", "similar")
    ),
    expand_grid(
      stim = 46:90,
      stim_type = stim_types,
      cresp = "new"
    )
  )
  # with similar
  repeat {
    seq_post <- slice_sample(stim_pool, prop = 1L)
    if (validate(seq_post)) {
      break
    }
  }
  n_block <- 2L
  seq_post |>
    add_column(run_id = 1L, .before = 1L) |>
    # cut into two blocks
    mutate(
      block_id = rep(seq_len(n_block), each = n() / n_block),
      trial_id = rep(seq_len(n() / n_block), times = n_block),
      .after = run_id
    )
}

validate <- function(seq) {
  # balance similar before old
  counts <- seq |>
    filter(cresp %in% c("old", "similar")) |>
    mutate(order = row_number()) |>
    pivot_wider(names_from = cresp, values_from = order) |>
    mutate(seq_type = if_else(similar > old, "sim_pre", "sim_rear")) |>
    count(stim_type, seq_type)
  # looks very hacky :(
  # valid_sim_old <- with(
  #   counts,
  #   n[stim_type == "object" & seq_type == "sim_pre"] == 22L &&
  #     n[stim_type == "place" & seq_type == "sim_pre"] == 23L &&
  #     n[stim_type == "face" & seq_type == "sim_pre"] == 22L &&
  #     n[stim_type == "word" & seq_type == "sim_pre"] == 23L
  # )
  if (!all(counts$n %in% c(22L, 23L))) {
    return(FALSE)
  }
  # similar images do not come continuously
  if (!all(with(seq, rle(str_c(stim_type, stim)))$lengths == 1L)) {
    return(FALSE)
  }
  return(TRUE)
}
