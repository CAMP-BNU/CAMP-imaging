#' Generate Sequence for Tasks without Similar Response
#'
#' @title generate_seq
#' @param seq The formal sequence.
#' @return
#' @author Liang Zhang
#' @export
generate_seq <- function(seq) {
  set.seed(1)
  old <- seq |>
    group_by(stim_type, stim) |>
    filter(n() == 2) |>
    ungroup() |>
    distinct(stim_type, stim)
  stim_pool <- bind_rows(
    old = old,
    similar = old |>
      filter(stim_type %in% c("object", "place")),
    new = old |>
      count(stim_type) |>
      mutate(stim = map(n, ~ seq(36, length.out = .))) |>
      unnest(stim) |>
      select(-n),
    .id = "cresp"
  )
  # no similar
  repeat {
    seq_post_no_sim <- stim_pool |>
      filter(stim_type %in% c("face", "word")) |>
      slice_sample(prop = 1L)
    if (all(rle(seq_post_no_sim$cresp)$lengths <= 5L)) {
      break
    }
  }
  # with similar
  repeat {
    seq_post_sim <- stim_pool |>
      filter(stim_type %in% c("object", "place")) |>
      slice_sample(prop = 1L)
    if (validate(seq_post_sim)) {
      break
    }
  }
  bind_rows(
    seq_post_no_sim,
    seq_post_sim,
    .id = "run_id"
  ) |>
    group_by(run_id) |>
    mutate(trial_id = row_number()) |>
    ungroup() |>
    select(run_id, trial_id, stim_type, stim, cresp)
}

validate <- function(seq) {
  # similar before old: exact 22 for object, exact 23 for place
  counts <- seq |>
    filter(cresp %in% c("old", "similar")) |>
    mutate(order = row_number()) |>
    pivot_wider(names_from = cresp, values_from = order) |>
    mutate(seq_type = if_else(similar > old, "sim_pre", "sim_rear")) |>
    count(stim_type, seq_type)
  valid_sim_old <- with(
    counts,
    n[stim_type == "object" & seq_type == "sim_pre"] == 22L &&
      n[stim_type == "place" & seq_type == "sim_pre"] == 23L
  )
  if (!valid_sim_old) {
    return(FALSE)
  }
  # similar images do not come continuously
  rle_id <- seq |>
    mutate(stim_id = str_c(stim_type, stim)) |>
    pull(stim_id) |>
    rle()
  valid_no_rep_id <- all(rle_id$lengths == 1L)
  if (!valid_no_rep_id) {
    return(FALSE)
  }
  all(rle(seq$cresp)$lengths <= 5L)
}
