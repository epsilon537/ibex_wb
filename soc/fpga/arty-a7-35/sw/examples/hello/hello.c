#include <stdint.h>

#include "../../libs/soc/platform.h"
#include "../../libs/soc/uart.h"
#include "../../libs/soc/gpio.h"
#include "../../libs/soc/utils.h"

static struct uart uart0;
static struct gpio gpio0;

int main(void) {
  uint32_t leds = 0xF;

  gpio_init(&gpio0, (volatile void *) PLATFORM_GPIO0_BASE);
  gpio_set_direction(&gpio0, 0x0000000F);

  uart_init(&uart0, (volatile void *) PLATFORM_UART_BASE);
  uart_set_baudrate(&uart0, 115200, PLATFORM_CLK_FREQ);
  uart_printf(&uart0, "Hello, World!\r\n");

  for (;;) {
    gpio_set_output(&gpio0, leds);
    leds ^= 0xF;
    usleep(500 * 1000);
  }
}
