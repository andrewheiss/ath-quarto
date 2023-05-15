// Stuff from R
data {
  int<lower=0> often_us;
  int<lower=0> total_us;
  int<lower=0> often_mexico;
  int<lower=0> total_mexico;
}

// Things to estimate
parameters {
  real<lower=0, upper=1> pi_us;
  real<lower=0, upper=1> pi_mexico;
}

// Prior and likelihood
model {
  pi_us ~ beta(2, 6);
  pi_mexico ~ beta(2, 6);
  
  often_us ~ binomial(total_us, pi_us);
  often_mexico ~ binomial(total_mexico, pi_mexico);
}
