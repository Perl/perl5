/*
 Check whether stdckdint.h functionality is available.
 If it's available, then 'have_stdckdint.exe' will be created
 by config_sh.PL.
 $Config{i_stdckdint} and the XS symbol I_STDCKDINT will be
 defined if and only if 'have_stdckdint.exe' prints '0'
 when executed.
 Else $Config{i_stdckdint} and I_STDCKDINT will be undef.
*/

#include <stdio.h>
#include <stdckdint.h>
static int func_l(long *resultptr, long a, long b) {
    return (ckd_add(resultptr, a, b) ||
	    ckd_sub(resultptr, a, b) ||
	    ckd_mul(resultptr, a, b)) ? 1 : 0;
}

static int func_ll(long long *resultptr, long long a, long long b) {
    return (ckd_add(resultptr, a, b) ||
	    ckd_sub(resultptr, a, b) ||
	    ckd_mul(resultptr, a, b)) ? 1 : 0;
}

int main(void) {
    long lresult_1, lresult_2;
    long long llresult_1, llresult_2;
    int ret, lret_1, lret_2, llret_1, llret_2;
    lret_1 = func_l(&lresult_1, 42L, 53L);
    lret_2 = func_l(&lresult_2, 10485777L, 1048555L);
    llret_1 = func_ll(&llresult_1, 42LL, 53LL);
    llret_2 = func_ll(&llresult_2, 34359738333LL, 34359738887LL);

    if(lret_1 == 0 && llret_1 == 0 &&
       lret_2 == 1 && llret_2 == 1 &&
       lresult_1 == 2226L && llresult_1 == 2226LL &&
       lresult_2 == -202375525L && llresult_2 == 16630113351947LL )  ret = 0;
    else ret = -1;
    printf("%d", ret);
    return 0;
}

