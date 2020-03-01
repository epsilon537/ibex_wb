# Makefile for soc library

all:
	riscv32-unknown-elf-gcc -c -O1 \
	-march=rv32im -mabi=ilp32 \
	-fdata-sections -ffunction-sections *.c
clean:
	rm -f *.o