// Stan implementation of John Kruschke's Bayesian Estimation Supersedes the 
// t-test (BEST), in John K. Kruschke, "Bayesian Estimation Supersedes the t 
// test," *Journal of Experimental Psychology* 142, no. 2 (May 2013): 573–603, 
// doi:10.1037/a0029146.

// Adapted from code by Michael Clark
// https://github.com/m-clark/Miscellaneous-R-Code/blob/master/ModelFitting/Bayesian/rstant_testBEST.R

// Stuff coming in from R
data {
  int<lower=1> N;  // Sample size
  int<lower=2> n_groups;  // Number of groups
  vector[N] y;  // Outcome variable
  int<lower=1, upper=n_groups> group_id[N];  // Group variable
}

// Stuff to transform in Stan
transformed data {
  real mean_y;
  
  mean_y = mean(y); 
}

// Stuff to estimate
parameters {
  vector[2] mu;  // Estimated group means 
  vector<lower=0>[2] sigma;  // Estimated group sd
  real<lower=0, upper=100> nu;  // df for t distribution
}

// Models and distributions
model {
  // Priors
  // curve(expr = dnorm(mean_y, 2), from = -5, to = 5)
  mu ~ normal(mean_y, 2);
  
  // curve(expr = dcauchy(x, location = 0, scale = 1), from = 0, to = 40)
  sigma ~ cauchy(0, 1);
  
  // Kruschke uses a nu of exponential(1/29)
  // curve(expr = dexp(x, 1/29), from = 0, to = 200)
  nu ~ exponential(1.0/29);
  
  
  // Likelihood
  for (n in 1:N){
    y[n] ~ student_t(nu, mu[group_id[n]], sigma[group_id[n]]);
  }
}

// Stuff to calculate with Stan
generated quantities {
  // Mean difference
  real mu_diff;
  
  // Effect size; see footnote 1 in Kruschke:2013
  // Standardized difference between two means
  // See https://en.wikipedia.org/wiki/Effect_size#Cohen's_d
  real cohen_d;
  
  // Common language effect size
  // The probability that a score sampled at random from one distribution will 
  // be greater than a score sampled from some other distribution
  // See https://janhove.github.io/reporting/2016/11/16/common-language-effect-sizes
  real cles;

  mu_diff = mu[1] - mu[2];
  cohen_d = mu_diff / sqrt(sum(sigma)/2);
  cles = normal_cdf(mu_diff / sqrt(sum(sigma)), 0, 1);
}
