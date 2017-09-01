#include <sys/types.h>
#define _K ((off_t)1024)
#define _M ((off_t)1024 * _K)
#define _G ((off_t)1024 * _M)
#define _T ((off_t)1024 * _G)

int test[(((64 * _G -1) % 671088649) == 268434537) && (((_T - (64 * _G -1) + 255) % 1792151290) == 305159546)? 1: -1];

int main() {
    return 0;
}