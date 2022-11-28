// Modified from code generated with brms 2.16.3

// ADD 2 NEW LINES
functions {
  void add_iter();  // ~*~THIS IS NEW~*~
  int get_iter();  // ~*~THIS IS NEW~*~
}

// REMOVE 1 LINE; ADD 2 NEW LINES
data {
  int<lower=1> N;  // total number of observations
  vector[N] Y;  // response variable
  //vector<lower=0>[N] weights;  // model weights -- ~*~REMOVE THIS~*~
  int<lower=1> K;  // number of population-level effects
  matrix[N, K] X;  // population-level design matrix
  int prior_only;  // should the likelihood be ignored?
  int L;  // number of columns in the weights matrix -- ~*~THIS IS NEW~*~
  matrix[N, L] IPW;  // weights matrix -- ~*~THIS IS NEW~*~
}

// NO CHANGES
transformed data {
  int Kc = K - 1;
  matrix[N, Kc] Xc;  // centered version of X without an intercept
  vector[Kc] means_X;  // column means of X before centering
  for (i in 2:K) {
    means_X[i - 1] = mean(X[, i]);
    Xc[, i - 1] = X[, i] - means_X[i - 1];
  }
}

// NO CHANGES
parameters {
  vector[Kc] b;  // population-level effects
  real Intercept;  // temporary intercept for centered predictors
  real<lower=0> sigma;  // dispersion parameter
}

// NO CHANGES
transformed parameters {
}

// ADD 2 LINES
model {
  // likelihood including constants
  if (!prior_only) {
    // initialize linear predictor term
    vector[N] mu = Intercept + Xc * b;
    
    int M = get_iter();  // get the current iteration -- ~*~THIS IS NEW~*~
    vector[N] weights = IPW[, M];  // get the weights for this iteration -- ~*~THIS IS NEW~*~

    for (n in 1:N) {
      target += weights[n] * (normal_lpdf(Y[n] | mu[n], sigma));
    }
  }
  // priors including constants
  target += normal_lpdf(b | 0, 2.5);
  target += student_t_lpdf(Intercept | 3, 0, 2.5);
  target += student_t_lpdf(sigma | 3, 0, 14.8)
    - 1 * student_t_lccdf(0 | 3, 0, 14.8);
}

// ADD 1 LINE
generated quantities {
  // actual population-level intercept
  real b_Intercept = Intercept - dot_product(means_X, b);
  
  add_iter();  // update the counter each iteration --  ~*~THIS IS NEW~*~
}
