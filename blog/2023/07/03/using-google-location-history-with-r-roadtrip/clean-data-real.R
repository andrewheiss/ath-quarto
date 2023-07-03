library(tidyverse)
library(jsonlite)
library(sf)
library(lutz)

meters_to_miles <- function(x) {
  x / 1609.344
}

# Start and end timestamps ------------------------------------------------

official_times <- list(
  there = list(
    start = ymd_hms("2023-06-03 11:34:01", tz = "UTC"),
    end = ymd_hms("2023-06-09 21:06:03", tz = "UTC")
  ),
  back_again = list(
    start = ymd_hms("2023-06-20 14:58:26", tz = "UTC"),
    end = ymd_hms("2023-06-25 16:51:12", tz = "UTC")
  )
)


# Places that weren't gas or bathroom breaks
not_driving_stops <- c(
  "ChIJnwDSTcsDnogRLyt_lqVprLY",  # Hotel in New Orleans, LA
  "ChIJgcNDAhKmIIYRRA4mio_7VgE",  # Parking in the French Quarter
  "ChIJv30_Xw-mIIYRpt26QbLBh58",  # Louis Armstrong Park
  "ChIJ59n6fW8dnogRWi-5N6olcyU",  # Chalmette Battlefield
  "ChIJ_7z4c1_2XIYR6b9p0NvEiVE",  # Hotel in San Antonio, TX
  "ChIJX4k2TVVfXIYRIsTnhA-P-Rc",  # The Alamo
  "ChIJAdu5Qad544YRhyJT8qzimi4",  # Hotel in Carlsbad, NM
  "ChIJW9e4xBN544YRvbI7vfc91G4",  # Carlsbad Caverns
  "ChIJERiZZMWOLYcRQbo78w80s34",  # Hotel in Flagstaff, AZ
  "ChIJrSLbJJIQM4cR4l5HTswDY8k",  # Grand Canyon
  "ChIJw_8NjzERSocRoMj48srdz9c",  # Cabin in Grover, UT
  "ChIJU6LnB_8ASocRB_9PSFPsO94",  # Capitol Reef
  "ChIJIw-BhQkZSocRncIWG0YMLJU",  # Capitol Reef Visitor Center
  "ChIJ6VbxQZIXSocR-SpwZ6W5ens",  # Capitol Reef Goosenecks
  "ChIJaSHejn29SYcR-YzTt_DNlTg",  # Goblin Valley
  "ChIJUUCyjPG8TYcR50RxmIdxSNw",  # Aunt's house in Spanish Fork, UT
  "ChIJVQ4oZOP4VFMREjDKbf7bHIE",  # Sister's house in Shelley, ID
  "ChIJp4yR8asLVFMRJJExTuHrYEs",  # Porter's Park in Rexburg, ID
  "ChIJGyd1jm8LVFMRzgcOZZumVzU",  # Hotel in Rexburg, ID
  "ChIJ3zGqpb65UVMR0rTSaqVZ5kc",  # Yellowstone
  "ChIJXy5ZgRvtUVMRoSJoWid8Owg",  # Old Faithful
  "ChIJSWHsxv8JTlMR82z8b6wF_BM",  # Place that had snow on the side of the road in Yellowstone
  "ChIJzTXkoTKUNFMRRC1n33hYsEQ",  # Hotel in Gilette, WY
  "ChIJOT5U8z8GM1MResed1BOdJKk",  # Devil's Tower
  "ChIJ39Y-tdg1fYcRQcZcBb499do",  # Mount Rushmore
  "ChIJWWVl4b_KjocRCMsTmFCHahQ",  # Hotel in Sioux Falls, SD
  "ChIJg_2MNnKRk4cRQGXbuvgqba4",  # Visitors Center in Winter Quarters
  "ChIJ36q1kAYm54cR36q-3xRQA4Y",  # Hotel in Nauvoo, IL
  "ChIJh53YJHIm54cRmpf8_ZA3CVw",  # Nauvoo visitors center
  "ChIJDUPPu3Im54cRKj6BG8UkOko",  # Nauvoo temple
  "ChIJg0abVHYm54cR85yQbfLjt2o",  # Nauvoo family living center
  "ChIJm7cRetkl54cR-lEKk-eZnXA",  # Smith family cemetery
  "ChIJZ6tHUwsm54cRbmWsF639PjY",  # Carthage jail
  "ChIJtUcJ-n36ZIgRhzY2PM19eWA",  # Hotel in Nashville, TN
  "ChIJGUwR7Juh9YgRHxAIB27Mi-U"   # Home
)

# Records.json ------------------------------------------------------------

all_locations_raw <- read_json("data_real/Records.json", simplifyVector = TRUE) %>% 
  # Pull out the "locations" slot (this is the same as doing full_data$locations)
  pluck("locations") %>% 
  # Make this a tibble just so it prints nicer here on the blog
  as_tibble() 

all_locations <- all_locations_raw %>% 
  mutate(timestamp = ymd_hms(timestamp, tz = "UTC")) %>% 
  filter(
    (timestamp >= official_times$there$start & 
        timestamp <= official_times$there$end) |
      (timestamp >= official_times$back_again$start & 
          timestamp <= official_times$back_again$end)
  ) %>% 
  # Scale down the location data (divide any column that ends in E7 by 10000000)
  mutate(across(ends_with("E7"), ~ . / 1e7)) %>% 
  # Create a geometry column with the coordinates
  st_as_sf(coords = c("longitudeE7", "latitudeE7"), crs = st_crs("EPSG:4326")) %>% 
  # Make a column with the time zone for each point
  mutate(tz = tz_lookup(., method = "accurate")) %>% 
  # Convert the timestamp to an actual UTC-based timestamp
  mutate(timestamp = ymd_hms(timestamp, tz = "UTC")) %>% 
  # Create a version of the timestamp in local time, but in UTC
  group_by(tz) %>% 
  mutate(timestamp_local = force_tz(with_tz(timestamp, tz), "UTC")) %>% 
  ungroup() %>% 
  # Add a column for direction
  mutate(
    direction = ifelse(timestamp <= ymd("2023-06-15", tz = "UTC"), "There", "Back again"),
    direction = fct_inorder(direction)
  ) %>% 
  # Add some helper columns for filtering, grouping, etc.
  mutate(
    year = year(timestamp_local),
    month = month(timestamp_local),
    day = day(timestamp_local)
  ) %>% 
  mutate(
    day_month = strftime(timestamp_local, "%B %e"),
    # With %e, there's a leading space for single-digit numbers, so we remove
    # any double spaces and replace them with single spaces 
    # (e.g., "June  3" becomes "June 3")
    day_month = str_replace(day_month, "  ", " "),
    day_month = fct_inorder(day_month)
  )

# Combine all the points in the day into a connected linestring
daily_routes <- all_locations %>% 
  group_by(day_month) %>% 
  nest() %>% 
  mutate(path = map(data, ~st_cast(st_combine(.), "LINESTRING"))) %>% 
  unnest(path) %>% 
  st_set_geometry("path")


# Semantic location history -----------------------------------------------

## placeVisits ------------------------------------------------------------

# Computer friendly timezones like America/New_York work for computers, but I
# want to sometimes show them as US-standard abbreviations like EDT (Eastern
# Daylight Time), so here's a little lookup table we can use to join to bigger
# datasets for better abbreviations
tz_abbreviations <- tribble(
  ~tz,                ~tz_abb,
  "America/New_York", "EDT",
  "America/Chicago",  "CDT",
  "America/Denver",   "MDT",
  "America/Phoenix",  "MST",
  "America/Boise",    "MDT"
)

place_visits_raw <- read_json(
  "data_real/Semantic Location History/2023/2023_JUNE.json", 
  simplifyVector = FALSE
) %>% 
  # Extract the timelineObjects JSON element
  pluck("timelineObjects") %>%
  # Filter the list to only keep placeVisits
  # { More verbose function-based approach: map(~ .x[["placeVisit"]]) }
  # Neat selection-based approach with just the name!
  map("placeVisit") %>% 
  # Discard all the empty elements (i.e. the activitySegments)
  compact()

place_visits <- place_visits_raw %>% 
  # Extract parts of the nested list
  map(~{
    tibble(
      id = .x$location$placeId,
      latitudeE7 = .x$location$latitudeE7 / 1e7,
      longitudeE7 = .x$location$longitudeE7 / 1e7,
      name = .x$location$name,
      address = .x$location$address,
      startTimestamp = ymd_hms(.x$duration$startTimestamp, tz = "UTC"),
      endTimestamp = ymd_hms(.x$duration$endTimestamp, tz = "UTC")
    )
  }) %>% 
  list_rbind() %>% 
  filter(
    (endTimestamp >= official_times$there$start & 
        startTimestamp <= official_times$there$end) |
      (endTimestamp >= official_times$back_again$start & 
          startTimestamp <= official_times$back_again$end)
  ) %>%
  # Calculate the duration of the stop
  mutate(duration = endTimestamp - startTimestamp) %>% 
  # Make an indicator for if the stop was a gas or bathroom break
  mutate(driving_stop = !(id %in% not_driving_stops)) %>%
  # Make a geometry column
  st_as_sf(coords = c("longitudeE7", "latitudeE7"), crs = st_crs("EPSG:4326")) %>% 
  # Make a column with the time zone for each point
  mutate(tz = tz_lookup(., method = "accurate")) %>% 
  # Create a version of the timestamp in local time, but in UTC
  group_by(tz) %>% 
  mutate(
    startTimestamp_local = force_tz(with_tz(startTimestamp, tz), "UTC"),
    endTimestamp_local = force_tz(with_tz(endTimestamp, tz), "UTC")
  ) %>% 
  ungroup() %>% 
  # Add a column for direction
  mutate(
    direction = ifelse(startTimestamp <= ymd("2023-06-15", tz = "UTC"), "There", "Back again"),
    direction = fct_inorder(direction)
  ) %>% 
  # Add some helper columns for filtering, grouping, etc.
  mutate(
    year = year(startTimestamp_local),
    month = month(startTimestamp_local),
    day = day(startTimestamp_local)
  ) %>% 
  # The first stop of each direction of the trip starts on the previous day
  # (since we slept either at home or at my aunt's house in Spanish Fork, Utah),
  # so use the ending time (i.e. the departure time) for the day_month for those
  # entries
  group_by(direction) %>% 
  mutate(
    day_month = ifelse(
      row_number() == 1, 
      strftime(endTimestamp_local, "%B %e"), 
      strftime(startTimestamp_local, "%B %e")
    ),
    # With %e, there's a leading space for single-digit numbers, so we remove
    # any double spaces and replace them with single spaces 
    # (e.g., "June  3" becomes "June 3")
    day_month = str_replace(day_month, "  ", " "),
    day_month = fct_inorder(day_month)
  ) %>%
  ungroup() %>% 
  # Bring in abbreviated time zones
  left_join(tz_abbreviations, by = join_by(tz)) %>% 
  # Fix some missing values + anonymize some addresses
  mutate(
    name = case_when(
      id == "ChIJGUwR7Juh9YgRHxAIB27Mi-U" ~ "Home",
      id == "ChIJVQ4oZOP4VFMREjDKbf7bHIE" ~ "My sister's house",
      id == "ChIJUUCyjPG8TYcR50RxmIdxSNw" ~ "My aunt's house",
      id == "ChIJw_8NjzERSocRoMj48srdz9c" ~ "My aunt's cabin",
      TRUE ~ name
    ),
    address = case_when(
      id == "ChIJGUwR7Juh9YgRHxAIB27Mi-U" ~ "Atlanta, GA, USA",
      id == "ChIJVQ4oZOP4VFMREjDKbf7bHIE" ~ "Shelley, ID, USA",
      id == "ChIJUUCyjPG8TYcR50RxmIdxSNw" ~ "Spanish Fork, UT, USA",
      id == "ChIJw_8NjzERSocRoMj48srdz9c" ~ "Grover, UT, USA",
      TRUE ~ address
    )
  )


## activitySegments -------------------------------------------------------

activity_segments_raw <- read_json(
  "data_real/Semantic Location History/2023/2023_JUNE.json", 
  simplifyVector = FALSE
) %>% 
  # Extract the timelineObjects JSON element
  pluck("timelineObjects") %>%
  # Filter the list to only keep activitySegments
  map("activitySegment") %>%
  # Discard all the empty elements (i.e. the placeVisits)
  compact()

activity_segments_not_clean <- activity_segments_raw %>% 
  # Extract parts of the nested list
  map(~{
    tibble(
      distance_m = .x$distance,
      activity_type = .x$activityType,
      start_latitudeE7 = .x$startLocation$latitudeE7 / 1e7,
      start_longitudeE7 = .x$startLocation$longitudeE7 / 1e7,
      end_latitudeE7 = .x$endLocation$latitudeE7 / 1e7,
      end_longitudeE7 = .x$endLocation$longitudeE7 / 1e7,
      startTimestamp = ymd_hms(.x$duration$startTimestamp, tz = "UTC"),
      endTimestamp = ymd_hms(.x$duration$endTimestamp, tz = "UTC")
    )
  }) %>% 
  list_rbind() %>% 
  filter(
    (endTimestamp >= official_times$there$start & 
        startTimestamp <= official_times$there$end) |
      (endTimestamp >= official_times$back_again$start & 
          startTimestamp <= official_times$back_again$end)
  )

# ↑ that needs to be a separate data frame so that we can refer to it to make a
# geometry column for the end latitude/longitude
activity_segments <- activity_segments_not_clean %>% 
  # Calculate the duration and distance and speed of the segment
  mutate(duration = endTimestamp - startTimestamp) %>% 
  mutate(distance_miles = meters_to_miles(distance_m)) %>% 
  mutate(
    hours = as.numeric(duration) / 60,
    avg_mph = distance_miles / hours
  ) %>% 
  # Make two geometry columns
  st_as_sf(coords = c("start_longitudeE7", "start_latitudeE7"), crs = st_crs("EPSG:4326")) %>% 
  rename("geometry_start" = "geometry") %>% 
  mutate(geometry_end = st_geometry(
    st_as_sf(
      activity_segments_not_clean, 
      coords = c("end_longitudeE7", "end_latitudeE7"), 
      crs = st_crs("EPSG:4326"))
  )
  ) %>% 
  select(-end_longitudeE7, -end_latitudeE7) %>% 
  # Make a column with the time zone for each point
  mutate(tz_start = tz_lookup(geometry_start, method = "accurate")) %>% 
  mutate(tz_end = tz_lookup(geometry_end, method = "accurate")) %>% 
  # Create a version of the timestamps in local time, but in UTC
  group_by(tz_start) %>% 
  mutate(startTimestamp_local = force_tz(with_tz(startTimestamp, tz_start), "UTC")) %>% 
  ungroup() %>% 
  group_by(tz_end) %>% 
  mutate(endTimestamp_local = force_tz(with_tz(endTimestamp, tz_end), "UTC")) %>% 
  ungroup() %>% 
  # Add a column for direction
  mutate(
    direction = ifelse(startTimestamp <= ymd("2023-06-15", tz = "UTC"), "There", "Back again"),
    direction = fct_inorder(direction)
  ) %>% 
  # Add some helper columns for filtering, grouping, etc.
  mutate(
    year = year(startTimestamp_local),
    month = month(startTimestamp_local),
    day = day(startTimestamp_local)
  ) %>% 
  mutate(
    day_month = strftime(startTimestamp_local, "%B %e"),
    # With %e, there's a leading space for single-digit numbers, so we remove
    # any double spaces and replace them with single spaces 
    # (e.g., "June  3" becomes "June 3")
    day_month = str_replace(day_month, "  ", " "),
    day_month = fct_inorder(day_month)
  ) %>% 
  # Bring in abbreviated time zones for both the start and end time zones
  left_join(
    rename(tz_abbreviations, "tz_start_abb" = "tz_abb"), 
    by = join_by(tz_start == tz)
  ) %>% 
  left_join(
    rename(tz_abbreviations, "tz_end_abb" = "tz_abb"),
    by = join_by(tz_end == tz)
  ) %>% 
  # Create an id column so we can better reference individual activities 
  # Make it a character so it can combine with the place visit id column
  mutate(id = as.character(1:n()))


## All stops and activities -----------------------------------------------

all_stops_activities <- bind_rows(
  list(visit = place_visits, segment = activity_segments),
  .id = "type"
) %>% 
  arrange(startTimestamp)
all_stops_activities



# Save everything ---------------------------------------------------------

output <- tibble::lst(
  official_times, all_locations, tz_abbreviations, 
  place_visits, daily_routes, activity_segments, all_stops_activities
)
saveRDS(output, "data_real/clean_data.rds")

# Load this whole RDS file into the global environment like this:
# invisible(list2env(readRDS("data_real/clean_data.rds"), .GlobalEnv))
