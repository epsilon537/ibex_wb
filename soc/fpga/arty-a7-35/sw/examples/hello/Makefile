# Makefile to generate baremetal app

PROGRAM ?= hello
PROGRAM_CFLAGS = -Wall -g -O1
#ARCH = rv32imc
ARCH = rv32im
SRCS = $(PROGRAM).c $(wildcard ../../libs/soc/*.c)
INCS = -I../../libs/soc

PREFIX ?= riscv32-unknown-elf
CC := $(PREFIX)-gcc
OBJCOPY := $(PREFIX)-objcopy
OBJDUMP := $(PREFIX)-objdump

LINKER_SCRIPT ?= link.ld
CRT ?= crt0.S
CFLAGS ?= -march=$(ARCH) -mabi=ilp32 -static -mcmodel=medany \
	-fvisibility=hidden -ffunction-sections -fdata-sections \
	-nostdlib -nostartfiles $(PROGRAM_CFLAGS)
LDFLAGS ?= $(CFLAGS) -T $(LINKER_SCRIPT) -Wl,--gc-sections -Wl,--Map,$(PROGRAM).map

OBJS := ${SRCS:.c=.o} ${CRT:.S=.o}
DEPS = $(OBJS:%.o=%.d)

OUTFILES = $(PROGRAM).elf $(PROGRAM).mem $(PROGRAM).bin $(PROGRAM).dis

HEX2VMEM = ../../../scripts/hex2vmem.pl
SENDAPP = ../../../scripts/sendapp.sh

all: $(OUTFILES)

$(PROGRAM).elf: $(OBJS) $(LINKER_SCRIPT)
	$(CC) $(LDFLAGS) $(OBJS) -o $@ $(LIBS)

%.dis: %.elf
	$(OBJDUMP) -SD $^ > $@

%.mem: %.hex
	$(HEX2VMEM) $< > $@

%.hex: %.elf
	$(OBJCOPY) -O verilog --interleave-width=4 --interleave=4 --byte=0 $< $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.o: %.c
	$(CC) $(CFLAGS) -c $(INCS) -o $@ $<

%.o: %.S
	$(CC) $(CFLAGS) -c $(INCS) -o $@ $<

clean:
	$(RM) -f $(OBJS) $(DEPS) *.hex
	$(RM) -f $(OUTFILES) *.map

#distclean: clean
#	$(RM) -f $(OUTFILES) *.map

run:
	$(SENDAPP) $(PROGRAM).bin

