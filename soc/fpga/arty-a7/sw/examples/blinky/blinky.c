#include <stdint.h>

#include "../../libs/soc/platform.h"
#include "../../libs/soc/gpio.h"
#include "../../libs/soc/utils.h"

static struct gpio gpio0;

void main() {
  uint32_t leds;

  gpio_init(&gpio0, (volatile void *) PLATFORM_GPIO0_BASE);
  gpio_set_direction(&gpio0, 0x0000000F);

  leds = 0xF;
  for (;;) {
    gpio_set_output(&gpio0, leds);
    leds ^= 0xF;
    usleep(500 * 1000);
  }
}
