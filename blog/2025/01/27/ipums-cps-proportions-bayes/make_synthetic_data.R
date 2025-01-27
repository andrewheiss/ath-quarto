library(tidyverse)
library(synthpop)
library(qs2)

real_data_full <- qs_read(
  "~/Research projects/Current/Why Donors Donate/silent-skywalk/_targets/objects/data_sans_conjoint"
)

# Only keep some columns for {synthpop}
real_data_smaller <- real_data_full |> 
  select(
    gender = Q5.12,
    age = Q5.17,
    marital_status = Q5.13,
    education = Q5.14,
    donate_frequency = Q2.5,
    volunteer_frequency = Q2.10,
    voted = Q5.1
  ) |> 
  mutate(across(
    where(is.factor), 
    \(x) fct_relabel(x, \(y) str_replace(y, ".*: ", ""))
  ))

# Make synthetic data that has the same relationships and distributions as the real results
# (Seed from random.org)
synthetic_data <- syn(real_data_smaller, k = 1300, seed = 532742)

synthetic_data$syn

saveRDS(as_tibble(synthetic_data$syn), "synthetic_data.rds")
write_csv(synthetic_data$syn, "synthetic_data.csv")
