static unsigned fib(unsigned n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

volatile unsigned x = 7893, y = 2631;
unsigned zero_init;

int main(void) {
  if (fib(15) != 610) { return 1; }
  if (x * y != 20766483u) { return 2;}
  if (x / y != 3u) { return 3; }
  if (zero_init != 0) { return 4; }
  return 0;
}
