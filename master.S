#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

.equ THRESHOLD_DRY, 40
.equ THRESHOLD_WET, 61

.equ LCD_ADDR_W, 0x4E
.equ LCD_BL,    0x08
.equ LCD_EN,    0x04
.equ LCD_RS,    0x01

str_header:
    .byte '=','=','=',' ','F','E','R','T','I','L','I','Z','E','R'
    .byte ' ','S','C','H','E','D','U','L','E','R',' ','=','=','='
    .byte 0x0A, 0x0D, 0x00

str_lcd_init_ok:
    .byte '[','L','C','D',' ','O','K',']', 0x0A,0x0D, 0x00
str_lcd_init_fail:
    .byte '[','L','C','D',' ','F','A','I','L',']', 0x0A,0x0D, 0x00
str_boot:
    .byte '[','B','O','O','T',']', 0x0A,0x0D, 0x00

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

str_lcd_hum:
    .byte 'H','u','m','i','d','i','t','y',':', 0x00
str_lcd_optimal:
    .byte 'S','t',':','O','P','T','I','M','A','L', 0x00
str_lcd_dry:
    .byte 'S','t',':','D','R','Y',' ','S','I','R','A','M', 0x00
str_lcd_wet:
    .byte 'S','t',':','W','E','T',' ','T','U','N','G','G','U', 0x00
str_lcd_off:
    .byte 'S','E','N','S','O','R',' ','O','F','F', 0x00
str_lcd_ready:
    .byte 'F','e','r','t','i','l','i','z','e','r',' ','R','d','y', 0x00
str_lcd_press:
    .byte 'T','e','k','a','n',' ','t','o','m','b','o','l', 0x00

main:
    LDI R16, hi8(RAMEND)
    OUT SPH, R16
    LDI R16, lo8(RAMEND)
    OUT SPL, R16

    ; --- UART init DULU supaya bisa debug ---
    CLR R16
    STS UCSR0A, R16
    STS UBRR0H, R16
    LDI R16, 103
    STS UBRR0L, R16
    LDI R16, (1<<RXEN0)|(1<<TXEN0)
    STS UCSR0B, R16
    LDI R16, (1<<UCSZ00)|(1<<UCSZ01)
    STS UCSR0C, R16

    LDI ZL, lo8(str_boot)
    LDI ZH, hi8(str_boot)
    RCALL print_string

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

    RCALL TWI_INIT
    RCALL LCD_INIT
    TST R0
    BRNE lcd_failed
    LDI ZL, lo8(str_lcd_init_ok)
    LDI ZH, hi8(str_lcd_init_ok)
    RCALL print_string
    RJMP lcd_done
lcd_failed:
    LDI ZL, lo8(str_lcd_init_fail)
    LDI ZH, hi8(str_lcd_init_fail)
    RCALL print_string
lcd_done:

    CLR R17
    CLR R18
    CLR R23

    LDI ZL, lo8(str_header)
    LDI ZH, hi8(str_header)
    RCALL print_string

    TST R0
    BRNE skip_lcd_start
    RCALL LCD_CLEAR
    LDI R16, 0x80
    RCALL LCD_CMD
    LDI ZL, lo8(str_lcd_ready)
    LDI ZH, hi8(str_lcd_ready)
    RCALL LCD_PRINT_STR
    LDI R16, 0xC0
    RCALL LCD_CMD
    LDI ZL, lo8(str_lcd_press)
    LDI ZH, hi8(str_lcd_press)
    RCALL LCD_PRINT_STR
skip_lcd_start:

run:
    RCALL check_button
    TST R23
    BREQ run_idle
    RCALL SPI_RECEIVE
    RCALL print_humidity
    RCALL CHECK_CONDITION
    RCALL LCD_UPDATE
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
    RCALL LCD_CLEAR
    LDI R16, 0x80
    RCALL LCD_CMD
    LDI ZL, lo8(str_lcd_off)
    LDI ZH, hi8(str_lcd_off)
    RCALL LCD_PRINT_STR
    LDI R16, 0xC0
    RCALL LCD_CMD
    LDI ZL, lo8(str_lcd_press)
    LDI ZH, hi8(str_lcd_press)
    RCALL LCD_PRINT_STR
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

; =====================================================
; ===========   LCD I2C dengan TIMEOUT   ==============
; =====================================================
; R0 = flag global (0=OK, 1=GAGAL)

TWI_INIT:
    PUSH R16
    LDI R16, 72
    STS TWBR, R16
    LDI R16, 0x00
    STS TWSR, R16
    CLR R0
    POP R16
    RET

TWI_START:
    PUSH R16
    PUSH R17
    PUSH R18
    LDI R16, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    STS TWCR, R16
    LDI R17, 0xFF
    LDI R18, 0xFF
ts_wait:
    LDS R16, TWCR
    SBRC R16, TWINT
    RJMP ts_ok
    DEC R18
    BRNE ts_wait
    DEC R17
    BRNE ts_wait
    LDI R16, 1
    MOV R0, R16
ts_ok:
    POP R18
    POP R17
    POP R16
    RET

TWI_STOP:
    PUSH R16
    LDI R16, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS TWCR, R16
    POP R16
    RET

TWI_WRITE:
    PUSH R17
    PUSH R18
    PUSH R19
    STS TWDR, R16
    LDI R17, (1<<TWINT)|(1<<TWEN)
    STS TWCR, R17
    LDI R18, 0xFF
    LDI R19, 0xFF
tw_wait:
    LDS R17, TWCR
    SBRC R17, TWINT
    RJMP tw_ok
    DEC R19
    BRNE tw_wait
    DEC R18
    BRNE tw_wait
    LDI R17, 1
    MOV R0, R17
tw_ok:
    POP R19
    POP R18
    POP R17
    RET

PCF_WRITE:
    PUSH R16
    TST R0
    BRNE pcf_done
    RCALL TWI_START
    TST R0
    BRNE pcf_stop
    LDI R16, LCD_ADDR_W
    RCALL TWI_WRITE
    TST R0
    BRNE pcf_stop
    MOV R16, R24
    RCALL TWI_WRITE
pcf_stop:
    RCALL TWI_STOP
pcf_done:
    POP R16
    RET

LCD_SEND_NIBBLE:
    PUSH R24
    MOV R24, R25
    ANDI R24, 0xF0
    OR   R24, R26
    ORI  R24, LCD_BL
    ORI  R24, LCD_EN
    RCALL PCF_WRITE
    RCALL delay_short
    MOV R24, R25
    ANDI R24, 0xF0
    OR   R24, R26
    ORI  R24, LCD_BL
    RCALL PCF_WRITE
    RCALL delay_short
    POP R24
    RET

LCD_SEND_BYTE:
    PUSH R25
    PUSH R16
    MOV R25, R16
    ANDI R25, 0xF0
    RCALL LCD_SEND_NIBBLE
    POP R16
    PUSH R16
    MOV R25, R16
    SWAP R25
    ANDI R25, 0xF0
    RCALL LCD_SEND_NIBBLE
    POP R16
    POP R25
    RET

LCD_CMD:
    PUSH R26
    LDI R26, 0x00
    RCALL LCD_SEND_BYTE
    RCALL delay_2ms
    POP R26
    RET

LCD_DATA:
    PUSH R26
    LDI R26, LCD_RS
    RCALL LCD_SEND_BYTE
    RCALL delay_short
    POP R26
    RET

LCD_INIT:
    PUSH R16
    PUSH R24
    PUSH R25
    PUSH R26

    CLR R0
    RCALL delay_50ms

    LDI R24, LCD_BL
    RCALL PCF_WRITE
    TST R0
    BRNE li_done

    LDI R26, 0x00
    LDI R25, 0x30
    RCALL LCD_SEND_NIBBLE
    RCALL delay_5ms
    LDI R25, 0x30
    RCALL LCD_SEND_NIBBLE
    RCALL delay_short
    LDI R25, 0x30
    RCALL LCD_SEND_NIBBLE
    RCALL delay_short
    LDI R25, 0x20
    RCALL LCD_SEND_NIBBLE
    RCALL delay_short

    LDI R16, 0x28
    RCALL LCD_CMD
    LDI R16, 0x08
    RCALL LCD_CMD
    LDI R16, 0x01
    RCALL LCD_CMD
    RCALL delay_2ms
    LDI R16, 0x06
    RCALL LCD_CMD
    LDI R16, 0x0C
    RCALL LCD_CMD

li_done:
    POP R26
    POP R25
    POP R24
    POP R16
    RET

LCD_CLEAR:
    PUSH R16
    TST R0
    BRNE lc_done
    LDI R16, 0x01
    RCALL LCD_CMD
    RCALL delay_2ms
lc_done:
    POP R16
    RET

LCD_PRINT_STR:
    PUSH R16
    TST R0
    BRNE lps_done
lps_loop:
    LPM R16, Z+
    TST R16
    BREQ lps_done
    RCALL LCD_DATA
    RJMP lps_loop
lps_done:
    POP R16
    RET

LCD_PRINT_NUM:
    PUSH R16
    PUSH R20
    PUSH R21
    PUSH R24
    TST R0
    BRNE ln_done

    MOV R20, R17
    CLR R21
    CLR R24
ln_hundreds:
    CPI R20, 100
    BRLO ln_tens
    SUBI R20, 100
    INC R24
    RJMP ln_hundreds
ln_tens:
    CPI R20, 10
    BRLO ln_ones
    SUBI R20, 10
    INC R21
    RJMP ln_tens
ln_ones:
    TST R24
    BREQ ln_skip_h
    MOV R16, R24
    SUBI R16, -48
    RCALL LCD_DATA
ln_skip_h:
    TST R21
    BREQ ln_skip_t
    MOV R16, R21
    SUBI R16, -48
    RCALL LCD_DATA
    RJMP ln_print_ones
ln_skip_t:
    TST R24
    BREQ ln_print_ones
    LDI R16, '0'
    RCALL LCD_DATA
ln_print_ones:
    MOV R16, R20
    SUBI R16, -48
    RCALL LCD_DATA
ln_done:
    POP R24
    POP R21
    POP R20
    POP R16
    RET

LCD_UPDATE:
    PUSH R16
    PUSH ZL
    PUSH ZH
    TST R0
    BRNE lu_done

    RCALL LCD_CLEAR
    LDI R16, 0x80
    RCALL LCD_CMD
    LDI ZL, lo8(str_lcd_hum)
    LDI ZH, hi8(str_lcd_hum)
    RCALL LCD_PRINT_STR
    RCALL LCD_PRINT_NUM
    LDI R16, '%'
    RCALL LCD_DATA

    LDI R16, 0xC0
    RCALL LCD_CMD

    CPI R17, THRESHOLD_DRY
    BRSH lu_check_wet
    LDI ZL, lo8(str_lcd_dry)
    LDI ZH, hi8(str_lcd_dry)
    RJMP lu_print

lu_check_wet:
    CPI R17, THRESHOLD_WET
    BRLO lu_optimal
    LDI ZL, lo8(str_lcd_wet)
    LDI ZH, hi8(str_lcd_wet)
    RJMP lu_print

lu_optimal:
    LDI ZL, lo8(str_lcd_optimal)
    LDI ZH, hi8(str_lcd_optimal)

lu_print:
    RCALL LCD_PRINT_STR
lu_done:
    POP ZH
    POP ZL
    POP R16
    RET

delay_short:
    PUSH R20
    PUSH R21
    LDI R20, 10
ds_o: LDI R21, 200
ds_i: DEC R21
    BRNE ds_i
    DEC R20
    BRNE ds_o
    POP R21
    POP R20
    RET

delay_2ms:
    PUSH R20
    PUSH R21
    LDI R20, 4
d2_o: LDI R21, 250
d2_i: DEC R21
    BRNE d2_i
    DEC R20
    BRNE d2_o
    POP R21
    POP R20
    RET

delay_5ms:
    PUSH R20
    PUSH R21
    LDI R20, 10
d5_o: LDI R21, 250
d5_i: DEC R21
    BRNE d5_i
    DEC R20
    BRNE d5_o
    POP R21
    POP R20
    RET

delay_50ms:
    PUSH R20
    PUSH R21
    PUSH R22
    LDI R20, 50
d50_o: LDI R21, 200
d50_m: LDI R22, 200
d50_i: DEC R22
    BRNE d50_i
    DEC R21
    BRNE d50_m
    DEC R20
    BRNE d50_o
    POP R22
    POP R21
    POP R20
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