library(tidyverse)
library(truncnorm)
library(fabricatr)
library(scales)
library(ids)  # Generate random IDs

set.seed(12345)
happiness_data <- fabricate(
  years = add_level(
    # Create 10 years
    # Technically this is 11 years! But that's because I want a preceding year
    # when lagging outcomes and confounders, so we make 11, lag stuff and then
    # lop off the first year
    N = 11,
    year = 0:10,
    # Shocks across all countries in a year
    y_population_shock = rtruncnorm(N, 0.1, 0.1, a = 0),
    y_gdp_shock = rnorm(N, 0, 0.03),
    y_democracy_shock = rnorm(N, 0, 0.02),
    y_corruption_shock = rnorm(N, 0, 0.01)
  ),
  countries = add_level(
    # Create 152 countries
    N = 152,
    # Country-specific trends
    # Confounders
    c_population_base = rnorm(N, 16.5, 1),
    c_population_growth = rnorm(N, 0.04, 0.007),
    c_gdp_base = runif(N, 16, 20.5),
    c_gdp_growth = runif(N, 0, 0.1),
    c_gdp_growth_error = runif(N, 0, 0.05),
    c_democracy_base = runif(N, 0.2, 0.6),
    c_democracy_growth = rnorm(N, 0, 0.02),
    c_democracy_error = runif(N, 0, 0.05),
    c_corruption_base = runif(N, 0.1, 0.6),
    c_corruption_growth = rnorm(N, 0, 0.04),
    c_corruption_error = runif(N, 0, 0.01),
    
    # Treatment
    c_vacation_base = runif(N, 10, 16),
    c_vacation_growth = rnorm(N, 0.75, 0.75),
    c_policy_base = runif(N, 25, 75),
    c_policy_growth = rnorm(N, 1.5, 1),
    
    # Outcome
    c_happiness_base = runif(N, 20, 45),
    c_happiness_growth = rnorm(N, 0.4, 0.05),
    c_happiness_error = runif(N, 0, 0.7),
    nest = FALSE
  ),
  country_years = cross_levels(
    # Cross countries and years
    by = join(years, countries),
    
    # Build all confounders
    log_population = c_population_base + (year * c_population_growth),
    log_gdp = c_gdp_base + (0.4 * log_population) + y_gdp_shock + 
      (year * c_gdp_growth) + rnorm(N, sd = c_gdp_growth_error),
    gdp = exp(log_gdp),
    population = exp(log_population),
    gdp_cap = gdp / population,
    log_gdp_cap = log(gdp_cap),
    democracy = c_democracy_base + y_democracy_shock + 
      (year * c_democracy_growth) + rnorm(N, sd = c_democracy_error),
    democracy = rescale(democracy, to = c(0, 1)) * 100,
    corruption = c_corruption_base + y_corruption_shock + 
      (year * c_corruption_growth) + rnorm(N, sd = c_corruption_error),
    corruption = rescale(corruption, to = c(0, 1)) * 100,
    
    # Treatment + outcome, vacation days
    vacation_days = c_vacation_base + (year * c_vacation_growth) + 
      (0.00012 * gdp_cap) + (0.09 * democracy) + (-0.12 * corruption),
    vacation_days = round(vacation_days, 0),
    # THE CAUSAL EFFECT is 1.7 here. An additional vacation day increases happiness by 1.7
    happiness_vacation = c_happiness_base + (year * c_happiness_growth) + 
      rnorm(N, sd = c_happiness_error) + (0.00015 * gdp_cap) + (0.11 * democracy) + 
      (-0.15 * corruption) + (1.7 * vacation_days),
    
    # Treatment + outcome, 6-hour workday
    # Generate a latent score for adopting the policy, then rescale it to 0.05
    # to 0.6 and then use that probability in rbinom() to assign a country to
    # adopt the policy
    policy_score = c_policy_base + (year * c_policy_growth) + (0.00012 * gdp_cap) + 
      (0.15 * democracy) + (-0.29 * corruption) + rnorm(N, 0, 10),
    policy_prob = rescale(policy_score, to = c(0.05, 0.60)),
    policy_assigned = rbinom(N, 1, policy_prob)
  )
) %>% 
  # Make it so no countries set the policy in the first or second year (since
  # the second year is technically the first year; year 0 gets removed and is
  # only here for lagging purposes)
  mutate(policy_assigned = ifelse(year %in% c(0, 1), 0, policy_assigned)) %>% 
  # Once a country sets its policy, it's permanent, so find the cumulative sum
  # of the policy_assigned column in each country. If it's ever bigger than 0,
  # they have the policy; otherwise they don't
  group_by(countries) %>% 
  mutate(policy = ifelse(cumsum(policy_assigned) > 0, 1, 0)) %>% 
  ungroup() %>% 
  # Create the outcome variable for the binary policy 
  # THE CAUSAL EFFECT is 7 here. The policy increases happiness by 7 points
  mutate(happiness_policy = (rnorm(n(), 7, 3) * policy) + c_happiness_base + 
           (year * c_happiness_growth) + rnorm(n(), sd = c_happiness_error) + 
           (0.00015 * gdp_cap) + (0.11 * democracy) + (-0.15 * corruption) + 
           (0.7 * vacation_days) + rnorm(n(), 8, 2)) %>% 
  # Fix and remove a bunch of intermediate columns
  # Make the year more sensical
  mutate(year = 2009 + year) %>%
  # Round a bunch of stuff
  mutate(across(c(happiness_vacation, happiness_policy, democracy, corruption),
                ~round(., 1))) %>% 
  # Generate sets of pronouncable 5-letter sequences as country names
  group_by(countries) %>% 
  mutate(country = str_to_sentence(proquint(n_words = 1))) %>% 
  ungroup() %>% 
  # Remove and rearrange columns
  select(-years, -countries, -country_years, 
         -starts_with("y_"), -starts_with("c_"), 
         -policy_score, -policy_prob, -policy_assigned) %>% 
  select(country, year, vacation_days, policy, 
         happiness_vacation, happiness_policy, everything()) %>% 
  # Lag things
  group_by(country) %>% 
  mutate(lag_policy = lag(policy, default = 0),
         lag_happiness_policy = lag(happiness_policy)) %>% 
  mutate(lag_vacation_days = lag(vacation_days),
         lag_happiness_vacation = lag(happiness_vacation)) %>% 
  ungroup() %>% 
  # Remove first year now that we've lagged stuff
  filter(year != 2009)

write_csv(happiness_data, "happiness_data.csv")
