#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

.equ THRESHOLD_DRY, 40
.equ THRESHOLD_WET, 61

str_header:
    .byte '=','=','=',' ','F','E','R','T','I','L','I','Z','E','R'
    .byte ' ','S','C','H','E','D','U','L','E','R',' ','=','=','='
    .byte 0x0A, 0x0D, 0x00

str_humidity:
    .byte 'H','u','m','i','d','i','t','y',':',' ', 0x00

str_optimal:
    .byte 'S','T','A','T','U','S',':',' ','O','P','T','I','M','A','L'
    .byte 0x0A,0x0D
    .byte 'R','E','K','O','M','E','N','D','A','S','I',':',' '
    .byte 'P','U','P','U','K',' ','S','E','K','A','R','A','N','G','!'
    .byte 0x0A,0x0D, 0x00

str_dry:
    .byte 'S','T','A','T','U','S',':',' '
    .byte 'T','E','R','L','A','L','U',' ','K','E','R','I','N','G'
    .byte 0x0A,0x0D
    .byte 'R','E','K','O','M','E','N','D','A','S','I',':',' '
    .byte 'S','I','R','A','M',' ','D','U','L','U'
    .byte 0x0A,0x0D, 0x00

str_wet:
    .byte 'S','T','A','T','U','S',':',' '
    .byte 'T','E','R','L','A','L','U',' ','B','A','S','A','H'
    .byte 0x0A,0x0D
    .byte 'R','E','K','O','M','E','N','D','A','S','I',':',' '
    .byte 'T','U','N','G','G','U',' ','K','E','R','I','N','G'
    .byte 0x0A,0x0D, 0x00

str_separator:
    .byte '-','-','-','-','-','-','-','-','-','-'
    .byte 0x0A,0x0D, 0x00

str_on:
    .byte 'S','E','N','S','O','R',' ','O','N'
    .byte 0x0A,0x0D, 0x00

str_off:
    .byte 'S','E','N','S','O','R',' ','O','F','F'
    .byte 0x0A,0x0D, 0x00

str_persen:
    .byte '%',0x0A,0x0D, 0x00

main:
    LDI R16, hi8(RAMEND)
    OUT SPH, R16
    LDI R16, lo8(RAMEND)
    OUT SPL, R16

    SBI DDRD, 4
    SBI DDRD, 5
    SBI DDRD, 6
    SBI DDRD, 7
    CBI DDRD, 2
    SBI PORTD, 2
    CBI PORTD, 4
    CBI PORTD, 5
    CBI PORTD, 6
    CBI PORTD, 7

    SBI DDRB, 2
    SBI DDRB, 3
    CBI DDRB, 4
    SBI DDRB, 5
    SBI PORTB, 2
    LDI R16, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
    OUT SPCR, R16

    CLR R16
    STS UCSR0A, R16
    STS UBRR0H, R16
    LDI R16, 103
    STS UBRR0L, R16
    LDI R16, (1<<RXEN0)|(1<<TXEN0)
    STS UCSR0B, R16
    LDI R16, (1<<UCSZ00)|(1<<UCSZ01)
    STS UCSR0C, R16

    CLR R17
    CLR R18
    CLR R23           ; R23 = flag toggle (0=OFF, 1=ON)

    LDI ZL, lo8(str_header)
    LDI ZH, hi8(str_header)
    RCALL print_string

run:
    RCALL check_button
    TST R23
    BREQ run_idle
    RCALL SPI_RECEIVE
    RCALL print_humidity
    RCALL CHECK_CONDITION
    RCALL delay_500ms
    RJMP run

run_idle:
    CBI PORTD, 4
    CBI PORTD, 5
    CBI PORTD, 6
    CBI PORTD, 7
    RCALL delay_500ms
    RJMP run

check_button:
    SBIC PIND, 2
    RET
    RCALL delay_20ms
    SBIC PIND, 2
    RET
wait_release:
    SBIS PIND, 2
    RJMP wait_release
    TST R23
    BREQ btn_turn_on
btn_turn_off:
    CLR R23
    CBI PORTD, 4
    CBI PORTD, 5
    CBI PORTD, 6
    CBI PORTD, 7
    LDI ZL, lo8(str_off)
    LDI ZH, hi8(str_off)
    RCALL print_string
    RET
btn_turn_on:
    LDI R23, 1
    LDI ZL, lo8(str_on)
    LDI ZH, hi8(str_on)
    RCALL print_string
    RET

print_string:
    PUSH R16
print_string_loop:
    LPM R16, Z+
    TST R16
    BREQ print_string_done
    RCALL uart_transmit
    RJMP print_string_loop
print_string_done:
    POP R16
    RET

uart_transmit:
    PUSH R19
uart_wait:
    LDS R19, UCSR0A
    SBRS R19, UDRE0
    RJMP uart_wait
    STS UDR0, R16
    POP R19
    RET

SPI_RECEIVE:
    IN R16, SPSR
    IN R16, SPDR
    RCALL delay_100ms
    CBI PORTB, 2
    LDI R16, 0x00
    OUT SPDR, R16
SPI_WAIT:
    IN R16, SPSR
    SBRS R16, SPIF
    RJMP SPI_WAIT
    SBI PORTB, 2
    IN R17, SPDR
    RET

CHECK_CONDITION:
    CBI PORTD, 4
    CBI PORTD, 5
    CBI PORTD, 6
    CBI PORTD, 7
    CPI R17, THRESHOLD_DRY
    BRLO SOIL_DRY
    CPI R17, THRESHOLD_WET
    BRSH SOIL_WET
SOIL_OPTIMAL:
    SBI PORTD, 5
    SBI PORTD, 7
    RET
SOIL_DRY:
    SBI PORTD, 4
    RET
SOIL_WET:
    SBI PORTD, 6
    RET

print_humidity:
    PUSH R16
    PUSH R20
    PUSH R21
    PUSH R24

    LDI ZL, lo8(str_humidity)
    LDI ZH, hi8(str_humidity)
    RCALL print_string

    MOV R20, R17
    CLR R21
    CLR R24

ph_hundreds:
    CPI R20, 100
    BRLO ph_tens
    SUBI R20, 100
    INC R24
    RJMP ph_hundreds

ph_tens:
    CPI R20, 10
    BRLO ph_ones
    SUBI R20, 10
    INC R21
    RJMP ph_tens

ph_ones:
    TST R24
    BREQ ph_skip_hundreds
    MOV R16, R24
    SUBI R16, -48
    RCALL uart_transmit

ph_skip_hundreds:
    TST R21
    BREQ ph_skip_tens
    MOV R16, R21
    SUBI R16, -48
    RCALL uart_transmit

ph_skip_tens:
    MOV R16, R20
    SUBI R16, -48
    RCALL uart_transmit

    LDI ZL, lo8(str_persen)
    LDI ZH, hi8(str_persen)
    RCALL print_string

    CPI R17, THRESHOLD_DRY
    BRSH ph_check_wet
    LDI ZL, lo8(str_dry)
    LDI ZH, hi8(str_dry)
    RJMP ph_print_status

ph_check_wet:
    CPI R17, THRESHOLD_WET
    BRLO ph_optimal
    LDI ZL, lo8(str_wet)
    LDI ZH, hi8(str_wet)
    RJMP ph_print_status

ph_optimal:
    LDI ZL, lo8(str_optimal)
    LDI ZH, hi8(str_optimal)

ph_print_status:
    RCALL print_string

    LDI ZL, lo8(str_separator)
    LDI ZH, hi8(str_separator)
    RCALL print_string

    POP R24
    POP R21
    POP R20
    POP R16
    RET

delay_20ms:
    LDI R20, 20
d20_o: LDI R21, 200
d20_m: LDI R22, 200
d20_i: DEC R22
    BRNE d20_i
    DEC R21
    BRNE d20_m
    DEC R20
    BRNE d20_o
    RET

delay_100ms:
    LDI R20, 100
d100_o: LDI R21, 200
d100_m: LDI R22, 200
d100_i: DEC R22
    BRNE d100_i
    DEC R21
    BRNE d100_m
    DEC R20
    BRNE d100_o
    RET

delay_500ms:
    LDI R20, 250
d500_o: LDI R21, 200
d500_m: LDI R22, 200
d500_i: DEC R22
    BRNE d500_i
    DEC R21
    BRNE d500_m
    DEC R20
    BRNE d500_o
    RET