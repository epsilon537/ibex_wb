
#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Sleeps for microseconds.
 * @param usec	Sleep time in microseconds.
 * @return		Returns 0 for success.
 */
int usleep(unsigned long usec);

/**
 * Resets the performance counters.
 */
void pcount_reset();

/**
 * Stops cycle counter.
 */
void mcycle_stop();

/**
 * Starts cycle counter.
 */
void mcycle_start();

/**
 * Returns lower 32 bits of current cycle count.
 */
uint32_t mcycle_get32();

/**
 * Returns current cycle count.
 */
uint64_t mcycle_get64();

/**
 * Converts cycle counts to microseconds.
 */
uint64_t cc2us(uint64_t clock_cycle);

#ifdef __cplusplus
}
#endif

#endif /* UTILS_H */

