# Copied with tiiiiny modifications from Simon Couch's {wrapped}:
#
# - https://www.simonpcouch.com/blog/2022-12-01-listening-2022/
# - https://github.com/simonpcouch/wrapped/blob/main/R/wrap_library.R

#' Read in a Music xml library.
#' 
#' @param path The path to your `Library.xml` file.
#' @param year The year to filter on, as an integer.
#' @export
#' @examplesIf FALSE
#' wrap_library("Library.xml", 2022L)

library(tidyverse)

read_itunes_library <- function(path, year = 2022L) {
  raw <- xml2::read_xml(path)
  
  res <- xml2::as_list(raw)
  
  res <- purrr::pluck(res, "plist", "dict", "dict")
  
  res <- res[names(res) != "key"]
  
  res <- 
    tibble::enframe(res) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(value = list(tibble::enframe(value))) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(id = dplyr::row_number()) %>%
    dplyr::select(-name) %>%
    tidyr::unnest(value) %>%
    dplyr::mutate(
      entry_id = (dplyr::row_number() + (dplyr::row_number() %% 2)) / 2
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(value = dplyr::if_else(length(value) == 0L, list(list(NA)), list(value)),
           value = unlist(value)) %>%
    dplyr::ungroup() %>%
    tidyr::pivot_wider(id_cols = c(id, entry_id), names_from = name, values_from = value, values_fn = list) %>%
    tidyr::pivot_longer(cols = 4:ncol(.), names_to = "type", values_drop_na = TRUE) %>%
    dplyr::select(-type) %>%
    tidyr::pivot_wider(id_cols = id, names_from = key, values_from = value) %>%
    janitor::clean_names() %>%
    dplyr::select(id, track_title = name, artist, album_artist, album, genre, total_time, date_added, skip_count, play_count) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(dplyr::across(everything(), ~dplyr::if_else(is.null(.x), list(NA), list(.x)))) %>%
    dplyr::mutate(dplyr::across(everything(), unlist)) %>%
    dplyr::mutate(
      date_added = strsplit(date_added, "T"),
      date_added = date_added[1],
      date_added = lubridate::ymd(date_added),
      skip_count = as.numeric(skip_count),
      play_count = as.numeric(play_count),
      total_time = as.numeric(total_time)
    ) %>%
    dplyr::ungroup() %>%
    # dplyr::filter(lubridate::year(date_added) %in% year) %>%
    dplyr::arrange(dplyr::desc(play_count))

  res
}

music_start <- read_itunes_library("data-raw/Library_2024-01-01.xml")
saveRDS(music_start, "data-processed/music_start.rds")

# lol kids played this on repeat on accident, so I'll filter it out here
music_end <- read_itunes_library("data-raw/Library_2024-12-04.xml") |> 
  filter(album != "Music Of The Spheres [Explicit]")
saveRDS(music_end, "data-processed/music_end.rds")
