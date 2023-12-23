# Get the OS
OS=$(shell uname)

MCU ?= atmega328

# Tools
CC      = avr-gcc
OBJDUMP = avr-objdump
OBJCOPY = avr-objcopy
AVRDUDE = avrdude

# Flags
CFLAGS  = -mmcu=$(MCU) -Os
LDFLAGS =

ifdef DEBUG
	CFLAGS += -g
endif

# Serial port
TTY=minicom
TTY_PORT=/dev/ttyACM0
BAUDRATE=9600
TTY_OPT=-D $(TTY_PORT) -b $(BAUDRATE)

# Avrdude
AVRDUDE_MCU ?= $(MCU)
AVRDUDE_BITRATE ?= 1

# sources (?)
SRCS_C = $(wildcard *.c)
SRCS_ASM = $(wildcard *.S)
OBJS = $(patsubst %.c,%.o,$(SRCS_C)) $(patsubst %.S,%.o,$(SRCS_ASM))

# targets (?)
PROGRAM_ELF    = program.elf
PROGRAM_HEX    = program.hex
PROGRAM_ASM    = program.asm
DOWNLOAD_FLASH = download.hex
DOWNLOAD_LFUSE = lfuse.hex
DOWNLOAD_HFUSE = hfuse.hex
DOWNLOAD_EFUSE = efuse.hex

ifeq ($(OS), "Linux")
	PORT = /dev/ttyACM0
	TTY_PORT=/dev/ACM0
else
	PORT = /dev/ttys000
	TTY_PORT=/dev/ptmx
endif

all: $(PROGRAM_HEX) $(PROGRAM_ASM)

os:
	@echo "OS: $(OS)"

tty:
	$(TTY) $(TTY_OPT)

# Using USBasp
download:
	$(AVRDUDE) -p $(AVRDUDE_MCU) -c usbasp -P $(PORT) -B $(AVRDUDE_BITRATE) -v \
		-U flash:r:$(DOWNLOAD_FLASH):i \
	  -U lfuse:r:$(DOWNLOAD_LFUSE):b \
		-U hfuse:r:$(DOWNLOAD_HFUSE):b \
		-U efuse:r:$(DOWNLOAD_EFUSE):b
	$(OBJDUMP) -m avr -D $(DOWNLOAD_FLASH) > download.asm
	mkdir -p download
	mv download.asm $(DOWNLOAD_FLASH) \
		$(DOWNLOAD_LFUSE) $(DOWNLOAD_HFUSE) $(DOWNLOAD_EFUSE) \
		download

16MHz:
	$(AVRDUDE) -p $(AVRDUDE_MCU) -c usbasp -P $(PORT) -B $(AVRDUDE_BITRATE) -v \
		-U lfuse:w:0xff:m

backup:
	tar czf backup.tar.gz download

upload: $(PROGRAM_HEX)
	$(AVRDUDE) -p $(AVRDUDE_MCU) -c usbasp -P $(PORT) -B $(AVRDUDE_BITRATE) -v \
		-U flash:w:$(PROGRAM_HEX):i

clean:
	rm -f *.o *.elf *.hex

$(PROGRAM_ASM): $(PROGRAM_HEX)
	$(OBJDUMP) -m avr -D $< > $@

$(PROGRAM_HEX): $(PROGRAM_ELF)
	$(OBJCOPY) -O ihex -j.text -j.data $< $@

$(PROGRAM_ELF): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.S
	$(CC) -c -o $@ $<

.PHONY: download clean 16MHz
