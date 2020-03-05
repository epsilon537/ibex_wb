#include <string.h>

#include "uart.h"
#include "platform.h"
#include "utils.h"

#include "api.h"

static struct uart uart0;

void main() {
	unsigned char pk[CRYPTO_PUBLICKEYBYTES];
	unsigned char sk[CRYPTO_SECRETKEYBYTES];
	unsigned char ct[CRYPTO_CIPHERTEXTBYTES];
	unsigned char ss1[CRYPTO_BYTES];
	unsigned char ss2[CRYPTO_BYTES];

	int err_keypair, err_enc, err_dec;

	uart_init(&uart0, (volatile void *) PLATFORM_UART_BASE);
	uart_set_baudrate(&uart0, 115200, PLATFORM_CLK_FREQ);
	uart_printf(&uart0, "Start!\r\n");

	mtime_stop();
	pcount_reset();
	mtime_start();
	
	// all return 0 for sucess
	err_keypair = crypto_kem_keypair(pk, sk);
	err_enc = crypto_kem_enc(ct, ss1, pk);
	err_dec = crypto_kem_dec(ss2, ct, sk);

	mtime_stop();

	uart_printf(&uart0, "Clock Cycle (mtime64) = %d\r\n", mtime_get64());
	uart_printf(&uart0, "Microseconds = %d\r\n", cc2us(mtime_get64()));
	uart_printf(&uart0, "err_keypair:%d\r\n", err_keypair);
	uart_printf(&uart0, "err_enc:%d\r\n", err_enc);
	uart_printf(&uart0, "err_dec:%d\r\n", err_dec);
	uart_printf(&uart0, "memcmp(ss1, ss2):%d\r\n", memcmp(ss1, ss2, CRYPTO_BYTES));

	uart_printf(&uart0, "\r\nss1:\r\n");
	for (int i = 0; i < CRYPTO_BYTES; i++)
		uart_printf(&uart0, "%02x ", ss1[i]);
	uart_printf(&uart0, "\r\n");

	uart_printf(&uart0, "\r\nss2:\r\n");
	for (int i = 0; i < CRYPTO_BYTES; i++)
		uart_printf(&uart0, "%02x ", ss2[i]);
	uart_printf(&uart0, "\r\n");
}
