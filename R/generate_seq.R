#' Generate Sequence for Tasks without Similar Response
#'
#' @title generate_seq
#' @return
#' @author Liang Zhang
NULL

#' @rdname generate_seq
#' @export
generate_seq_no_sim <- function() {
  repeat {
    seq <- expand_grid(
      stim_type = c("word", "face"),
      stim = seq_len(90L)
    ) |>
      mutate(cresp = if_else(stim <= 45L, "old", "new")) |>
      slice_sample(prop = 1L)
    if (all(rle(seq$cresp)$lengths <= 5L)) {
      break
    }
  }
  seq |>
    mutate(trial_id = seq_len(n()), .before = 1L)
}

#' @rdname generate_seq
#' @export
generate_seq_sim <- function() {
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
  repeat {
    seq <- bind_rows(
      expand_grid(
        stim_type = c("object", "place"),
        stim = 1:45,
        cresp = c("old", "similar")
      ),
      expand_grid(
        stim_type = c("object", "place"),
        stim = 46:90
      ) |>
        add_column(cresp = "new")
    ) |>
      slice_sample(prop = 1L)
    if (validate(seq)) {
      break
    }
  }
  seq |>
    mutate(trial_id = seq_len(n()), .before = 1L)
}
