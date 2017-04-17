
hwimage.flash: ../output_files/DE0_Nano.sof
	sof2flash --input=$< --output=$@ --epcs --verbose

swimage.flash: ../software/LELEC2103-SW/LELEC2103-SW.elf hwimage.flash
	elf2flash --input=$< --output=$@ --epcs --after=hwimage.flash --verbose

%.hex: %.flash
	nios2-elf-objcopy -I srec -O ihex $< $@

default: all

all: hwimage.hex swimage.hex

