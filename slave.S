#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
    LDI R16, hi8(RAMEND)
    OUT SPH, R16
    LDI R16, lo8(RAMEND)
    OUT SPL, R16

    CBI DDRB, 2
    CBI DDRB, 3
    SBI DDRB, 4
    CBI DDRB, 5

    LDI R16, (1<<SPE)
    OUT SPCR, R16

    LDI R16, (1<<REFS0)|(1<<ADLAR)
    STS ADMUX, R16
    LDI R16, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    STS ADCSRA, R16

    CLR R19

slave_loop:
    RCALL SOIL_READ
    OUT SPDR, R19
    RJMP slave_loop

SOIL_READ:
    LDS R16, ADCSRA
    ORI R16, (1<<ADSC)
    STS ADCSRA, R16
wait_adc:
    LDS R16, ADCSRA
    SBRC R16, ADSC
    RJMP wait_adc
    LDS R19, ADCH

    LDI R16, 255
    SUB R16, R19
    MOV R19, R16

    MOV R24, R19
    LDI R25, 100
    MUL R24, R25
    MOV R19, R1
    CLR R1
    RET