# ---- broomify -----------------------------------------------------------
tidy.melded <- function(x, conf.int = FALSE, conf.level = 0.95) {
  # Get the df from one of the models
  model_degrees_freedom <- glance(x[[1]])$df.residual
  
  # Create matrices of the estimates and standard errors
  params <- tibble(models = unclass(x)) %>%
    mutate(m = 1:n(),
           tidied = models %>% map(tidy)) %>% 
    unnest(tidied) %>%
    select(m, term, estimate, std.error) %>%
    gather(key, value, estimate, std.error) %>%
    mutate(term = fct_inorder(term)) %>%  # Order the terms so that spread() keeps them in order
    spread(term, value)
  
  just_coefs <- params %>% filter(key == "estimate") %>% select(-m, -key)
  just_ses <- params %>% filter(key == "std.error") %>% select(-m, -key)
  
  # Meld the coefficients with Rubin's rules
  coefs_melded <- mi.meld(just_coefs, just_ses)
  
  # Create tidy output
  output <- as.data.frame(cbind(t(coefs_melded$q.mi),
                                t(coefs_melded$se.mi))) %>%
    magrittr::set_colnames(c("estimate", "std.error")) %>%
    mutate(term = rownames(.)) %>%
    select(term, everything()) %>%
    mutate(statistic = estimate / std.error,
           p.value = 2 * pt(abs(statistic), model_degrees_freedom, lower.tail = FALSE))
  
  # Add confidence intervals if needed
  if (conf.int & conf.level) {
    # Convert conf.level to tail values (0.025 when it's 0.95)
    a <- (1 - conf.level) / 2
    
    output <- output %>% 
      mutate(conf.low = estimate + std.error * qt(a, model_degrees_freedom),
             conf.high = estimate + std.error * qt((1 - a), model_degrees_freedom))
  }
  
  # tidy objects only have a data.frame class, not tbl_df or anything else
  class(output) <- "data.frame"
  output
}

glance.melded <- function(x) {
  # Because the properly melded parameters and the simple average of the
  # parameters of these models are roughly the same (see
  # https://www.andrewheiss.com/blog/2018/03/07/amelia-tidy-melding/), for the
  # sake of simplicty we just take the average here
  output <- tibble(models = unclass(x)) %>%
    mutate(glance = models %>% map(glance)) %>%
    unnest(glance) %>%
    summarize_at(vars(r.squared, adj.r.squared, sigma, statistic, p.value, df, 
                      logLik, AIC, BIC, deviance, df.residual),
                 list(mean)) %>%
    mutate(m = as.integer(length(x)))
  
  # glance objects only have a data.frame class, not tbl_df or anything else
  class(output) <- "data.frame"
  output
}

nobs.melded <- function(x, ...) {
  # Take the number of observations from the first model
  nobs(x[[1]])
}
