// Simple bootloader for Ibex Wishbone
// Reads binary image file from UART, writes to ram
// and jumps to program.

#include <stdint.h>
#include <string.h>
#include "../../libs/soc/uart.h"
#include "../../libs/soc/platform.h"
#include "../../libs/soc/utils.h"

#define APP_START (0x00010000) // Main RAM Address
#define APP_LEN  (0x00070000) // 448kB
#define APP_ENTRY (APP_START + 0x80)

static struct uart uart0;

static uint32_t pow_int(uint32_t a, uint32_t b) {
	uint32_t result = 1;
	while (b--)
		result *= a;

	return result;
}

static uint32_t parse_int(const char *str) {
	uint32_t len = strlen(str);
	uint32_t val = 0;

	for (int i = 0; i < len; i++) {
		val += (uint32_t) (str[len - i - 1] - '0') * pow_int(10, i);
	}

	return val;
}

void main(void) {
	uint32_t image_size = 0;
	uint32_t load_interval = 1;
	char str[50];

	uart_init(&uart0, (volatile void *) PLATFORM_UART_BASE);
	uart_set_baudrate(&uart0, 115200, PLATFORM_CLK_FREQ);
	uart_printf(&uart0, "\r\n** Ibex Bootloader - Waiting for application image **\r\n");

	uart_rx_line(&uart0, str);
	image_size = parse_int(str);

	if (image_size > APP_LEN) {
		uart_printf(&uart0, "Application image is too big!\r\n");
		return;
	}
	
	load_interval = image_size / 50;

	for (uint32_t i = 0; i < image_size; i++) {
		while (!uart_rx_ready(&uart0))
			;
		*((volatile uint8_t*)(APP_START + i)) = uart_rx(&uart0);

		if (i % load_interval == 0) {
			uart_printf(&uart0, "\r%02d%%", i * 100 / image_size);
		}
	}

	uart_printf(&uart0, "\r100%%");

	for (uint32_t i = image_size; i < APP_LEN; i++)
		*((volatile uint8_t*)(APP_START + i)) = 0;

	uart_printf(&uart0, "\r\nBooting\r\n\r\n");

	usleep(200 * 1000); // 0.2 seconds

	goto *APP_ENTRY;

}
