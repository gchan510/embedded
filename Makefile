# Get the OS
OS=$(shell uname)

# Tools
CC=avr-gcc
OBJDUMP=avr-objdump
AVRDUDE=avrdude

# Flags
CFLAGS=-mmcu=atmega328p

TTY=minicom
TTY_PORT=/dev/ttyACM0
BAUDRATE=9600
TTY_OPT=-D $(TTY_PORT) -b $(BAUDRATE)

HEX=program.hex
DOWNLOAD_HEX=download.hex

ifeq ($(OS), "Linux")
	PORT = /dev/ttyACM0
	TTY_PORT=/dev/ACM0
else
	PORT = /dev/ttys000
	TTY_PORT=/dev/ptmx
endif

os:
	@echo "OS: $(OS)"

program:
	$(CC) 

tty:
	$(TTY) $(TTY_OPT)

# Using USBasp
download_usbasp:
	$(AVRDUDE) -p atmega328p -c usbasp -P $(PORT) -U flash:r:$(DOWNLOAD_HEX):i
	$(OBJDUMP) -m avr -D $(DOWNLOAD_HEX) > download.asm

# Using the Arduino
download:
	$(AVRDUDE) -p atmega328p -c arduino -P $(PORT) -U flash:r:$(DOWNLOAD_HEX):i
	$(OBJDUMP) -m avr -D $(DOWNLOAD_HEX) > download.asm

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
