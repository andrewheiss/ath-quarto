# A guide to 

# Use gapminder or vdem to get country structure?
# Or use this? https://solomonkurz.netlify.app/post/2021-09-22-sexy-up-your-logistic-regression-model-with-logit-dotplots/

# https://twitter.com/bmwiernik/status/1458043604128215040?s=21

# These things? https://rpsychologist.com/GLMM-part1-lognormal

# https://paul-buerkner.github.io/brms/reference/emmeans-brms-helpers.html

# Life expectancy e_pelifeex

# Explore data
# Modeling approach: multilevel model with region and year effects (could do all sorts of nesting - link to that one lme4 table that shows them all)
# Types of Bayesian posterior prediction: linpred vs. epred
# Linear models (beta)
# Nonlinear models (beta)

library(tidyverse)
library(vdemdata)
library(brms)
library(tidybayes)
library(broom)
library(broom.mixed)
library(patchwork)
library(emmeans)

# Make a subset of the full V-Dem data
vdem_clean <- vdem %>% 
  select(country_name, country_text_id, year, region = e_regionpol_6C,
         polyarchy = v2x_polyarchy, civil_liberties = v2x_civlib, 
         media_index = v2xme_altinf, v2psoppaut_ord) %>% 
  filter(year >= 2010, year < 2020) %>% 
  mutate(party_autonomy = v2psoppaut_ord >= 3,
         party_autonomy = ifelse(is.na(party_autonomy), FALSE, TRUE)) %>% 
  # mutate(across(c(year, country_name), factor)) %>% 
  mutate(region = factor(region, labels = c("Eastern Europe and Central Asia",
                                            "Latin America and the Caribbean",
                                            "Middle East and North Africa",
                                            "Sub-Saharan Africa",
                                            "Western Europe and North America",
                                            "Asia and Pacific")))

vdem_2015 <- vdem_clean %>% 
  filter(year == 2015)

ggplot(vdem_2015, aes(x = media_index, fill = factor(party_autonomy))) +
  geom_density()

ggplot(vdem_2015, aes(x = polyarchy, y = v2xme_altinf)) +
  geom_point()

vdem_2015 %>% count(compulsory)

thing <- lm(media_index ~ party_autonomy + polyarchy, data = vdem_2015)
broom::tidy(thing)


model <- brm(
  bf(media_index ~ party_autonomy + civil_liberties + (1 | region),
     phi ~ (1 | region)),
  data = vdem_2015,
  family = Beta(),
  control = list(adapt_delta = 0.85),
  chains = 4, iter = 2000, warmup = 1000,
  cores = 4, seed = 1234, 
  backend = "cmdstanr"
)

model_big <- brm(
  bf(media_index ~ party_autonomy + civil_liberties + (1 | region) + (1 | year),
     phi ~ (1 | region) + (1 | year)),
  data = vdem_2015,
  family = Beta(),
  control = list(adapt_delta = 0.85),
  chains = 4, iter = 2000, warmup = 1000,
  cores = 4, seed = 1234, 
  backend = "cmdstanr"
)

tidy(model)

vdem_2015 %>% 
  group_by(region) %>% 
  summarize(avg = mean(media_index))

newdata <- expand_grid(party_autonomy = c(TRUE, FALSE),
                       # region = levels(vdem_2015$region),
                       region = "Some hypothetical region",
                       civil_liberties = c(0.5))

thing <- model %>% 
  epred_draws(newdata = newdata, re_formula = NULL, allow_new_levels = TRUE)

ggplot(thing, aes(x = .epred, y = region, fill = factor(party_autonomy))) +
  stat_halfeye() +
  labs(x = "Predicted media index")


# TODO:
# - Global grand mean
# - Means for each region
# - Means for a hypothetical region

# https://twitter.com/bmwiernik/status/1458130315386445824

# Grand mean
# Expected value of media index, ignoring any region-specific deviations of the intercept or slopes
# Set re_formula to NA, which omits group-level effects
preds <- model %>% 
  epred_draws(newdata = expand_grid(party_autonomy = c(TRUE, FALSE),
                                    civil_liberties = c(0.5)), 
              re_formula = NA)

model %>% 
  emmeans(~ party_autonomy,
          at = list(civil_liberties = 0.5),
          epred = TRUE, re_formula = NA) %>% 
  contrast(method = "revpairwise")

plot_grand_mean <- ggplot(preds, aes(x = .epred, y = "Grand mean", 
                                     fill = factor(party_autonomy))) +
  stat_halfeye() +
  labs(x = "Predicted media index", y = NULL,
       fill = "Opposition parties allowed",
       title = "Grand mean",
       subtitle = "re_formula = NA") +
  theme_bw() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))
plot_grand_mean

# Conditional effects for specific regions that already exist in the data. This
# incorporates region-specific deviations in slope/intercept
# Use re_formula = NULL and set region to some existing level in newdata
preds <- model %>% 
  epred_draws(newdata = expand_grid(party_autonomy = c(TRUE, FALSE),
                                    region = levels(vdem_2015$region),
                                    civil_liberties = c(0.5)), 
              re_formula = NULL)

model %>% 
  emmeans(~ party_autonomy + region,
          at = list(civil_liberties = 0.5, region = levels(vdem_2015$region)),
          # epred = TRUE, re_formula = ~ (1 | region)) %>% 
          epred = TRUE, re_formula = NULL) %>% 
  contrast(method = "revpairwise", by = "region")


plot_regions <- ggplot(preds, aes(x = .epred, y = region, 
                                  fill = factor(party_autonomy))) +
  stat_halfeye() +
  labs(x = "Predicted media index", y = NULL,
       fill = "Opposition parties allowed",
       title = "Region-specific means",
       subtitle = "re_formula = NULL; existing region(s) included in newdata") +
  theme_bw() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))
plot_regions

# Effects for a single new hypothetical region
# Use re_formula = NULL and set region to NA in the newdata, or set region to
# something in the newdata and include allow_new_levels = TRUE
preds <- model %>% 
  epred_draws(newdata = expand_grid(party_autonomy = c(TRUE, FALSE),
                                    region = "Some new region",
                                    civil_liberties = c(0.5)), 
              re_formula = NULL, allow_new_levels = TRUE)

model %>% 
  emmeans(~ party_autonomy + region,
          at = list(civil_liberties = 0.5, region = "Some new region"),
          epred = TRUE, re_formula = NULL, allow_new_levels = TRUE) %>% 
  contrast(method = "revpairwise", by = "region")

plot_new_region <- ggplot(preds, aes(x = .epred, y = region, 
                                     fill = factor(party_autonomy))) +
  stat_halfeye() +
  labs(x = "Predicted media index", y = NULL,
       fill = "Opposition parties allowed",
       title = "Mean for hypothetical region",
       subtitle = "re_formula = NULL; new region included in newdata") +
  theme_bw() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))
plot_new_region

plot_grand_mean | plot_regions | plot_new_region


model <- brm(
  bf(media_index ~ party_autonomy + civil_liberties + (1 | region),
     phi ~ (1 | region)),
  data = vdem_2015,
  family = Beta(),
  control = list(adapt_delta = 0.85),
  chains = 4, iter = 2000, warmup = 1000,
  cores = 4, seed = 1234, 
  backend = "cmdstanr"
)

ame_hypothetical <- model %>% 
  emmeans(~ party_autonomy + region,
          at = list(civil_liberties = 0.5, region = "Some new region"),
          epred = TRUE, re_formula = NULL, 
          # Use sample_new_levels when including new levels!
          # https://bookdown.org/ajkurz/Statistical_Rethinking_recoded/multilevel-models.html
          # This makes it so that the new fake region uses a multivariate normal
          # distribution implied by the group-level standard deviations and
          # correlations - without it, brms samples from the characteristics of
          # the existing regions. See ?prepare_predictions.brmsfit
          allow_new_levels = TRUE, sample_new_levels = "gaussian") %>% 
  contrast(method = "revpairwise", by = "region") %>% 
  gather_emmeans_draws()

ame_hypothetical %>% median_hdi()

ggplot(ame_hypothetical, aes(x = .value)) +
  stat_halfeye()

ame_hypothetical_big <- model_big %>% 
  emmeans(~ party_autonomy + year + region,
          at = list(civil_liberties = 0.5, region = levels(vdem_clean$region)),
          epred = TRUE, re_formula = ~ (1 | year) + (1 | region), 
          allow_new_levels = TRUE, sample_new_levels = "gaussian") %>% 
  contrast(method = "revpairwise", by = "region") %>% 
  gather_emmeans_draws()

ggplot(ame_hypothetical_big, aes(x = .value, y = region)) +
  stat_halfeye()

# TODO: Explain re_formula NULL vs. NA vs. explicit formula (https://groups.google.com/g/brms-users/c/FI8vZLeFD4Y?pli=1)
# TODO: brms::posterior_epred vs. tidybayes::epred_draws
# TODO: Gaussian model?
# TODO: Logit model, or just beta?
# TODO: linpred vs. epred (epred takes everything into account?) Find E[] math expression for it?
# TODO: emtrends continuous thing with delta method
# TODO: Just year, just region, both, none
