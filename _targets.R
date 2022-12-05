library(targets)
purrr::walk(fs::dir_ls("R"), source)
tar_option_set(packages = c("magick", "tidyverse"))
future::plan(future.callr::callr)
list(
  seq_post = list(
    tar_target(
      seq_post,
      generate_seq_post()
    ),
    tar_target(
      file_seq_post,
      write_csv(seq_post, "stimuli/seq_post.csv")
    )
  )
)
