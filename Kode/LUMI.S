; LightMonitorSystem.S

#include <avr/io.h>

; Pin definitions
.equ GREEN_LED, 1    ; PB1 (Digital 9)
.equ RED_LED, 2      ; PB2 (Digital 10)
.equ LDR_CHANNEL, 0  ; ADC0 (PC0)

; Constants
.equ LIGHT_THRESHOLD_LOW, 244   ; 500 & 0xFF (low byte)
.equ LIGHT_THRESHOLD_HIGH, 1    ; 500 >> 8 (high byte)

.section .text

; ========================================
; setupPins - Setup pin I/O
; ========================================
.global setupPins
setupPins:
    push r16
    push r17
    
    ; Set PB1 (Green LED) dan PB2 (Red LED) sebagai output
    in r16, _SFR_IO_ADDR(DDRB)
    ori r16, (1 << GREEN_LED) | (1 << RED_LED)
    out _SFR_IO_ADDR(DDRB), r16
    
    ; Matikan kedua LED initially
    in r16, _SFR_IO_ADDR(PORTB)
    andi r16, ~((1 << GREEN_LED) | (1 << RED_LED))
    out _SFR_IO_ADDR(PORTB), r16
    
    pop r17
    pop r16
    ret

; ========================================
; setupADC - Setup ADC untuk sensor cahaya
; ========================================
.global setupADC
setupADC:
    push r16
    
    ; Set ADMUX: AVCC reference, ADC0 channel
    ldi r16, (1 << REFS0)  ; AVCC reference, channel 0
    sts _SFR_MEM_ADDR(ADMUX), r16
    
    ; Set ADCSRA: Enable ADC, prescaler 128
    ldi r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    sts _SFR_MEM_ADDR(ADCSRA), r16
    
    pop r16
    ret

; ========================================
; readLightSensor - Baca sensor LDR
; Return: r24-r25 (16-bit ADC value)
; ========================================
.global readLightSensor
readLightSensor:
    push r16
    push r17
    
    ; Start ADC conversion
    lds r16, _SFR_MEM_ADDR(ADCSRA)
    ori r16, (1 << ADSC)  ; Set ADSC bit
    sts _SFR_MEM_ADDR(ADCSRA), r16
    
    ; Wait for conversion complete
wait_adc:
    lds r16, _SFR_MEM_ADDR(ADCSRA)
    sbrc r16, ADSC        ; Skip if ADSC = 0
    rjmp wait_adc
    
    ; Read ADC result (ADCL first, then ADCH)
    lds r24, _SFR_MEM_ADDR(ADCL)      ; Low byte to r24
    lds r25, _SFR_MEM_ADDR(ADCH)      ; High byte to r25
    
    pop r17
    pop r16
    ret

; ========================================
; setLEDs - Kontrol LED Green dan Red
; Parameters: r24 = greenOn (0/1), r22 = redOn (0/1)
; ========================================
.global setLEDs
setLEDs:
    push r16
    push r17
    
    ; Baca status PORTB saat ini
    in r16, _SFR_IO_ADDR(PORTB)
    
    ; Clear LED bits
    andi r16, ~((1 << GREEN_LED) | (1 << RED_LED))
    
    ; Set Green LED jika r24 != 0
    tst r24
    breq check_red
    ori r16, (1 << GREEN_LED)
    
check_red:
    ; Set Red LED jika r22 != 0
    tst r22
    breq write_portb
    ori r16, (1 << RED_LED)
    
write_portb:
    ; Write ke PORTB
    out _SFR_IO_ADDR(PORTB), r16
    
    pop r17
    pop r16
    ret

; ========================================
; blinkLEDTimes - Blink LED beberapa kali
; Parameters: r24 = pin (9 atau 10), r22 = count
; ========================================
.global blinkLEDTimes
blinkLEDTimes:
    push r16
    push r17
    push r18
    push r19
    push r20
    
    ; Convert Arduino pin to bit position
    ; Pin 9 = PB1 (bit 1), Pin 10 = PB2 (bit 2)
    mov r18, r24
    ldi r19, 1         ; Default bit 1 (Green LED)
    cpi r18, 10
    brne blink_loop
    ldi r19, 2         ; bit 2 (Red LED)
    
blink_loop:
    ; Check if count > 0
    tst r22
    breq blink_done
    
    ; Turn LED ON
    in r16, _SFR_IO_ADDR(PORTB)
    mov r17, r19
    ldi r20, 1
blink_shift_on:
    dec r17
    breq set_led_on
    lsl r20
    rjmp blink_shift_on
set_led_on:
    or r16, r20
    out _SFR_IO_ADDR(PORTB), r16
    
    ; Delay ~250ms (approximate)
    rcall delay_250ms
    
    ; Turn LED OFF
    in r16, _SFR_IO_ADDR(PORTB)
    com r20            ; Invert mask
    and r16, r20
    out _SFR_IO_ADDR(PORTB), r16
    
    ; Delay ~250ms
    rcall delay_250ms
    
    ; Decrement count
    dec r22
    rjmp blink_loop
    
blink_done:
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ret

; ========================================
; getThreshold - Return light threshold value
; Return: r24-r25 = 500
; ========================================
.global getThreshold
getThreshold:
    ldi r24, LIGHT_THRESHOLD_LOW
    ldi r25, LIGHT_THRESHOLD_HIGH
    ret

; ========================================
; delay_250ms - Delay approximately 250ms
; Assumes 16MHz clock
; ========================================
delay_250ms:
    push r16
    push r17
    push r18
    
    ; Outer loop count for ~250ms
    ldi r18, 250       ; ~1ms per iteration
    
delay_outer:
    ldi r17, 200       ; Inner loop
delay_middle:
    ldi r16, 80        ; Inner-inner loop
delay_inner:
    dec r16
    brne delay_inner
    dec r17
    brne delay_middle
    dec r18
    brne delay_outer
    
    pop r18
    pop r17
    pop r16
    ret