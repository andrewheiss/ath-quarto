// Stuff from R
data {
  int<lower=0> n;
  array[n] int<lower=0> often;
  array[n] int<lower=0> total;
}

// Things to estimate
parameters {
  vector<lower=0, upper=1>[n] pi;
}

// Prior and likelihood
model {
  pi ~ beta(2, 6);
  
  // We could specify separate priors like this
  // pi[1] ~ beta(2, 6);
  // pi[2] ~ beta(2, 6);
  
  often ~ binomial(total, pi);
}
