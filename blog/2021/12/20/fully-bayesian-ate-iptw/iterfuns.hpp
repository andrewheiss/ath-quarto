// Declare an integer to keep track of the iteration count
static int itct = 1;

// Increment the counter
inline void add_iter(std::ostream* pstream__) {
  itct += 1;
}

// Retrieve the current count
inline int get_iter(std::ostream* pstream__) {
  return itct;
}
