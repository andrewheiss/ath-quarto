---
title: Convert logistic regression standard errors to odds ratios with R
date: 2016-04-25
description: Correctly transform logistic regression standard errors to odds ratios using R
image: blank.png
categories: 
  - r
  - regression
---

Converting logistic regression coefficients and standard errors into odds ratios is trivial in Stata: just add `, or` to the end of a `logit` command:

```stata
. use "http://www.ats.ucla.edu/stat/data/hsbdemo", clear

. logit honors i.female math read, or

Logistic regression                             Number of obs     =        200
                                                LR chi2(3)        =      80.87
                                                Prob > chi2       =     0.0000
Log likelihood = -75.209827                     Pseudo R2         =     0.3496

------------------------------------------------------------------------------
      honors | Odds Ratio   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
      female |
     female  |   3.173393   1.377573     2.66   0.008      1.35524    7.430728
        math |   1.140779   .0370323     4.06   0.000     1.070458     1.21572
        read |   1.078145    .029733     2.73   0.006     1.021417    1.138025
       _cons |   1.99e-06   3.68e-06    -7.09   0.000     5.29e-08    .0000749
------------------------------------------------------------------------------
```

Doing the same thing in R is a little trickier. Calculating odds ratios for *coefficients* is trivial, and `exp(coef(model))` gives the same results as Stata:

```r
# Load libraries
library(dplyr)  # Data frame manipulation
library(readr)  # Read CSVs nicely
library(broom)  # Convert models to data frames

# Use treatment contrasts instead of polynomial contrasts for ordered factors
options(contrasts=rep("contr.treatment", 2))

# Load and clean data
df <- read_csv("http://www.ats.ucla.edu/stat/data/hsbdemo.csv") %>%
  mutate(honors = factor(honors, levels=c("not enrolled", "enrolled")),
         female = factor(female, levels=c("male", "female"), ordered=TRUE))

# Run model
model <- glm(honors ~ female + math + read, data=df, family=binomial(link="logit"))
summary(model)
#>
#> Call:
#> glm(formula = honors ~ female + math + read, family = binomial(link = "logit"), 
#>     data = df)
#>
#> Deviance Residuals:
#>     Min       1Q   Median       3Q      Max  
#> -2.0055  -0.6061  -0.2730   0.4844   2.3953  
#>
#> Coefficients:
#>               Estimate Std. Error z value Pr(>|z|)    
#> (Intercept)  -13.12749    1.85080  -7.093 1.31e-12 ***
#> femalefemale   1.15480    0.43409   2.660  0.00781 ** 
#> math           0.13171    0.03246   4.058 4.96e-05 ***
#> read           0.07524    0.02758   2.728  0.00636 ** 
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#>
#> (Dispersion parameter for binomial family taken to be 1)
#>
#>     Null deviance: 231.29  on 199  degrees of freedom
#> Residual deviance: 150.42  on 196  degrees of freedom
#> AIC: 158.42
#>
#> Number of Fisher Scoring iterations: 5

# Exponentiate coefficients
exp(coef(model))
#>  (Intercept) femalefemale         math         read 
#> 1.989771e-06 3.173393e+00 1.140779e+00 1.078145e+00

# Exponentiate standard errors
# WRONG
ses <- sqrt(diag(vcov(model)))
exp(ses)
#>  (Intercept) femalefemale         math         read 
#>     6.364894     1.543557     1.032994     1.027961
```

Calculating the odds-ratio adjusted *standard errors* is less trivial—`exp(ses)` does not work. This is because of the underlying math behind logistic regression (and all other models that use odds ratios, hazard ratios, etc.). Instead of exponentiating, the standard errors have to be calculated with calculus (Taylor series) or simulation (bootstrapping). Stata uses the [Taylor series-based delta method](https://www.stata.com/support/faqs/statistics/delta-rule/), which is [fairly easy to implement in R](http://www.ats.ucla.edu/stat/r/faq/deltamethod.htm) (see Example 2).

Essentially, you can calculate the odds ratio-adjusted standard error with $\sqrt{\text{gradient} \times \text{coefficient variance} \times \text{gradient}}$, and since the first derivative/gradient of $e^x$ is just $e^x$, in this case the adjusted standard error is simply $\sqrt{e^{\text{coefficient}} \times \text{coefficient variance} \times e^{\text{coefficient}}}$ or $\sqrt{(e^{\text{coefficient}})^2 \times \text{coefficient variance}}$

Doing this in R is easy, especially with [`broom::tidy()`](https://github.com/dgrtwo/broom):

``` r
model.df <- tidy(model)  # Convert model to dataframe for easy manipulation
model.df
#>           term     estimate  std.error statistic      p.value
#> 1  (Intercept) -13.12749111 1.85079765 -7.092883 1.313465e-12
#> 2 femalefemale   1.15480121 0.43408932  2.660285 7.807461e-03
#> 3         math   0.13171175 0.03246105  4.057532 4.959406e-05
#> 4         read   0.07524236 0.02757725  2.728422 6.363817e-03

model.df %>% 
  mutate(or = exp(estimate),  # Odds ratio/gradient
         var.diag = diag(vcov(model)),  # Variance of each coefficient
         or.se = sqrt(or^2 * var.diag))  # Odds-ratio adjusted 
#>           term     estimate  std.error statistic      p.value           or
#> 1  (Intercept) -13.12749111 1.85079765 -7.092883 1.313465e-12 1.989771e-06
#> 2 femalefemale   1.15480121 0.43408932  2.660285 7.807461e-03 3.173393e+00
#> 3         math   0.13171175 0.03246105  4.057532 4.959406e-05 1.140779e+00
#> 4         read   0.07524236 0.02757725  2.728422 6.363817e-03 1.078145e+00
#>       var.diag        or.se
#> 1 3.4254519469 3.682663e-06
#> 2 0.1884335381 1.377536e+00
#> 3 0.0010537198 3.703090e-02
#> 4 0.0007605045 2.973228e-02
```

This can all be wrapped up into a simple function:

```r
get.or.se <- function(model) {
  broom::tidy(model) %>%
    mutate(or = exp(estimate),
           var.diag = diag(vcov(model)),
           or.se = sqrt(or^2 * var.diag)) %>%
    select(or.se) %>% unlist %>% unname
}

get.or.se(model)
#> [1] 3.682663e-06 1.377536e+00 3.703090e-02 2.973228e-02
```

Same results in both programs!

![Same!](same.gif "Same!")
