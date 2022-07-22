#include <stdint.h>

#include "../../libs/soc/platform.h"
#include "../../libs/soc/uart.h"
#include "../../libs/soc/gpio.h"
#include "../../libs/soc/utils.h"

#define GPIO1_SIM_INDICATOR 0xf //If GPIO1 inputs have this value, this is a simulation.

static struct uart uart0;
static struct gpio gpio0;
static struct gpio gpio1;

int main(void) {
  uint32_t leds = 0xF;

  gpio_init(&gpio0, (volatile void *) PLATFORM_GPIO0_BASE);
  gpio_set_direction(&gpio0, 0x0000000F); //4 inputs, 4 outputs

  gpio_init(&gpio1, (volatile void *) PLATFORM_GPIO1_BASE);
  gpio_set_direction(&gpio1, 0x00000000); //4 inputs

  uart_init(&uart0, (volatile void *) PLATFORM_UART_BASE);
  uart_set_baudrate(&uart0, 115200, PLATFORM_CLK_FREQ);
  uart_printf(&uart0, "Hello, World!\n");

  //GPIO1 bits3:0 = 0xf indicate we're running inside a simulator.
  if ((gpio_get_input(&gpio1) & 0xf) == GPIO1_SIM_INDICATOR)
    uart_printf(&uart0, "Sim.\n");    
  else
    uart_printf(&uart0, "Not Sim.\n");

  for (;;) {
    gpio_set_output(&gpio0, leds);
    leds ^= 0xF;

    if ((gpio_get_input(&gpio1) & 0xf) == GPIO1_SIM_INDICATOR)
      usleep(500); //Sleep less when we're running inside a simulator.
    else
      usleep(500 * 1000);
  }
}
