;Archivo: PROYECTORELOJ.s
;Dispositivo: PIC16F887
;Autor: Jimena de la Rosa
;Compilador: pic-as (v2.30). MPLABX v5.40
;Programa: Prelab 6
;Hardware: LEDs en el puerto A y led intermitente en el PORTB
;Creado: 13 MAR, 2022
;Ultima modificacion: 03 MAR, 2022
    
PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT UDATA_BANK0,global,class=RAM,space=1,delta=1,noexec
GLOBAL  BANDERAS, CONTM1, DISPLAY, CONT60, CONTM2, CONTH1, CONTH2, MODO, MODOIP
GLOBAL  CONTR, MODOEA, CONTMES, CONTDIA, CONTD1, CONTD2, CONTME1, CONTME2
    CONT60:      DS 1 ;SE NOMBRA UNA VARIABLE DE CONTADOR DE 4 BITS 
    CONTM1:    DS 1
    CONTM2:    DS 1
    CONTH1:    DS 1   
    CONTH2:    DS 1
    DISPLAY:  DS 4
    BANDERAS: DS 1
    MODO:     DS 1
    CONTR:    DS 1
    MODOEA:     DS 1
    MODOIP:	DS 1
    CONTMES:    DS 1
    CONTDIA:    DS 1
    CONTD1:    DS 1
    CONTD2:    DS 1
    CONTME1:    DS 1
    CONTME2:    DS 1


; -------------- MACROS --------------- 
; Macro para reiniciar el valor del TMR0
; Recibe el valor a configurar en TMR_VAR
RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM
    
; Macro para reiniciar el valor del TMR1
; Recibe el valor a configurar en TMR1_H y TMR1_L
RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H	    ; Literal a guardar en TMR1H
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   TMR1_L	    ; Literal a guardar en TMR1L
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L
    BCF	    TMR1IF	    ; Limpiamos bandera de int. TMR1
    ENDM
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    
    BTFSC   T0IF	    ; Interrupcion de TMR0?
    CALL    INT_TMR0
    BTFSC   TMR1IF	    ; Interrupcion de TMR1?
    CALL    INT_TMR1
    BTFSC   RBIF	    ; Fue interrupción del PORTB? No=0 Si=1
    CALL    INT_IOCB	    ; Si -> Subrutina o macro con codigo a ejecutar
    BTFSC   TMR2IF	    ; Interrupcion de TMR2?
    CALL    INT_TMR2

    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal  
; ------ SUBRUTINAS DE INTERRUPCIONES ------
INT_TMR0:
    RESET_TMR0 252	    ; Reiniciamos TMR0 para 2ms
    CALL   MOSTRAR_VALOR	; Mostramos valor en hexadecimal en los displays
    RETURN
    
INT_TMR1:
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1000ms
    BTFSS MODOIP,0
    RETURN
    CALL MINUTOS1
    RETURN
    
    
    
INT_TMR2:
    BCF	    TMR2IF
    RETURN
    
    
INT_IOCB:
   
    CALL INTERHORAS
    BCF RBIF
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
 TABLA:
    CLRF PCLATH
    BSF  PCLATH, 0
    ANDLW 0X0F; SE ASEGURA QUE SOLO EXISTAN 4 BITS
    ADDWF PCL
    RETLW 00111111B; 01000000B 0
    RETLW 00000110B ;01111001B 1
    RETLW 01011011B; 00100100B;2
    RETLW 01001111B ;00110000B;3
    RETLW 01100110B ;00011001B;4
    RETLW 01101101B ;00010010B;5
    RETLW 01111101B ;00000010B;6
    RETLW 00000111B ;01111000B;7
    RETLW 01111111B ;00000000B;8
    RETLW 01101111B ;00010000B;9
    RETLW 01110111B ;00001000B;A
;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0	    ; Configuración de TMR0
    CALL    CONFIG_TMR1	    ; Configuración de TMR1
    CALL    CONFIG_TMR2	    ; Configuración de TMR2
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    CALL    CONFIG_IOCRB
    BANKSEL PORTD	    ; Cambio a banco 00
 
    
LOOP:
    CALL SET_RELOJ
    GOTO LOOP
    	    
;------------- SUBRUTINAS ---------------
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 01
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BCF	    OSCCON, 4	    ; IRCF<2:0> -> 100 1MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 2ms
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BCF	    PS0		    ; PS<2:0> -> 110 prescaler 1 : 128
    
    BANKSEL TMR0	    ; Cambiamos a banco 00
    MOVLW   252
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN 
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; Cambiamos a banco 00
    BCF	    TMR1GE	    ; TMR1 siempre cuenta
    BSF	    T1CKPS1	    ; prescaler 1:4
    BCF	    T1CKPS0
    BCF	    T1OSCEN	    ; LP deshabilitado
    BCF	    TMR1CS	    ; Reloj interno
    BSF	    TMR1ON	    ; Prendemos TMR1
    
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1s
    RETURN
    
CONFIG_TMR2:
    BANKSEL PR2		    ; Cambiamos a banco 01
    MOVLW   49		    ; Valor para interrupciones cada 50ms
    MOVWF   PR2		    ; Cargamos litaral a PR2
    
    BANKSEL T2CON	    ; Cambiamos a banco 00
    BSF	    T2CKPS1	    ; prescaler 1:16
    BSF	    T2CKPS0
    
    BSF	    TOUTPS3	    ; postscaler 1:16
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    
    BSF	    TMR2ON	    ; prendemos TMR2
    RETURN
    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	    ; I/O digitales
    
    BANKSEL TRISD
    CLRF    TRISC	    ; PORTC como salida
    CLRF    TRISD	    ; PORTD como salida
    CLRF    TRISA	    ; PORTA como salida
    BSF     TRISB,0         ; PORTB como ENTRADA
    BSF     TRISB,1
    BSF     TRISB,2
    BSF     TRISB,3
    BSF     TRISB,4
    BCF	    OPTION_REG, 7; SE HABILITAN LOS PULL_UPS
    BSF	    WPUB, 0	
    BSF	    WPUB, 1
    BSF	    WPUB, 2
    BSF	    WPUB, 3
    BSF	    WPUB, 4
    
    BANKSEL PORTD
    CLRF    PORTB	    ; Apagamos PORTB
    CLRF    PORTA	    ; Apagamos PORTA
    CLRF    PORTC	    ; Apagamos PORTC
    CLRF    BANDERAS       ;SE LIMPIA LA VARIABLE
    CLRF    CONTM1          ;SE LIMPIA LA VARIABLE
    CLRF    CONTM2          ;SE LIMPIA LA VARIABLE
    CLRF    CONTH1          ;SE LIMPIA LA VARIABLE
    CLRF    CONTH2          ;SE LIMPIA LA VARIABLE
    CLRF    DISPLAY        ;SE LIMPIA LA VARIABLE
    CLRF    MODO
    CLRF    MODOEA
    BSF   MODOEA,0
    BSF   MODOEA,1
    CLRF    MODOIP
    BCF     MODOIP,0
    MOVLW   60
    MOVWF   CONT60
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1	    ; Cambiamos a banco 01
    BSF	    TMR1IE	    ; Habilitamos interrupciones de TMR1
    BSF	    TMR2IE	    ; Habilitamos interrupciones de TMR2
    
    BANKSEL INTCON	    ; Cambiamos a banco 00
    BSF	    PEIE	    ; Habilitamos interrupciones de perifericos
    BSF	    GIE		    ; Habilitamos interrupciones
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF	    ; Limpiamos bandera de TMR1
    BCF	    TMR2IF	    ; Limpiamos bandera de TMR2
    BSF	    RBIE
    BCF	    RBIF
    RETURN
 
CONFIG_IOCRB:
    BANKSEL TRISB
    BSF IOCB, 0    ; SE CONFIGURAN LOS PULL UPS DE LAS ENTRADAS
    BSF IOCB, 1
    BSF IOCB, 2
    BSF IOCB, 3
    BSF IOCB, 4
    
    BANKSEL PORTB
    MOVF    PORTB, W
    BCF	    RBIF    ; SE LIMPIA LA BANDERA DEL CAMBIO EN EL PORT B
    RETURN

MOSTRAR_VALOR:
    BCF	    PORTD, 0		; Apagamos display de nibble alto
    BCF	    PORTD, 1		; Apagamos display de nibble bajo
    BCF	    PORTD, 2		; Apagamos display de nibble alto
    BCF	    PORTD, 3		; Apagamos display de nibble bajo
    
    BTFSC   BANDERAS, 0		; Verificamos bandera
    GOTO    BANDERA1
    GOTO    BANDERA0
    		       

DISPLAY_0:			
	MOVF    DISPLAY, W	; Movemos display a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 0	; Encendemos display de nibble bajo
	BSF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BCF	BANDERAS, 1
    RETURN
    
DISPLAY_1:
	MOVF    DISPLAY+1, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 1	; Encendemos display de nibble bajo
	BCF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BSF	BANDERAS, 1
    RETURN
    
DISPLAY_2:
	MOVF    DISPLAY+2, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 2	; Encendemos display de nibble bajo
	BSF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BSF	BANDERAS, 1
    RETURN
    
DISPLAY_3:
	MOVF    DISPLAY+3, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 3	; Encendemos display de nibble bajo
	BCF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BCF	BANDERAS, 1
    RETURN


BANDERA0:
    BTFSC BANDERAS, 1
    GOTO DISPLAY_2
    GOTO DISPLAY_0
    
    
BANDERA1:
    BTFSC BANDERAS, 1
    GOTO DISPLAY_3
    GOTO DISPLAY_1

    
;FUNCION RELOJ 
RELOJ:
    DECFSZ   CONT60
    RETURN
    
MINUTOS1:
    MOVLW    60
    MOVWF    CONT60
    INCF CONTM1  ;SE INCREMENTA EL CONTADOR DE MINUTOS 1
    MOVF CONTM1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
 
    
MINUTOS2:   
    CLRF   CONTM1 ;SE LIMPIA EL CONTADOR DE UNIDADES
    INCF CONTM2	    ;SE INCREMENTA EL CONTADOR DE DECENAS
    MOVF CONTM2, W; se mueve el valor del contador a W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    
    
HORAS1:   
    CLRF   CONTM2 ;SE LIMPIA EL CONTADOR DE DECENAS
    INCF CONTH1  ;SE INCREMENTA EL CONTADOR DE MINUTOS 1
    MOVF CONTH1, W
    SUBLW 4; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    
HORAS2:   
    CLRF   CONTH1 ;SE LIMPIA EL CONTADOR DE DECENAS
    INCF CONTH2  ;SE INCREMENTA EL CONTADOR DE MINUTOS 1
    MOVF CONTH2, W
    SUBLW 3; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF   CONTH2 ;SE LIMPIA EL CONTADOR DE DECENAS
    RETURN

SET_RELOJ:
    MOVF    CONTM1, W		; Movemos nibble bajo a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY		; Guardamos en display
    
    MOVF    CONTM2, W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+1		; Guardamos en display+1
    
    MOVF    CONTH1, W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+2		; Guardamos en display+1
    
    MOVF    CONTH2, W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+3		; Guardamos en display+1
    RETURN
    
    
INTERHORAS:
    BTFSS  PORTB, 0
    GOTO   INC_RELOJ
    BTFSS  PORTB, 3
    GOTO   INPA_RELOJ
    BTFSS  PORTB, 2
    GOTO   EDAC_RELOJ
    BTFSS  PORTB, 1
    GOTO   DEC_RELOJ
   RETURN

INPA_RELOJ: ; MODO 1 INICIAR, MODO 0 PARAR
    BTFSS MODOIP,0
    GOTO  INICIAR_RELOJ

PARAR_RELOJ:
    BCF   MODOIP,0
    BSF   MODOEA,0
    BSF   MODOEA,1
    RETURN
 

INICIAR_RELOJ:
    BSF MODOIP,0
    RETURN

EDAC_RELOJ:
    BTFSC MODOIP, 0
    RETURN
    
EDITAR_RELOJ:
    BTFSC   MODOEA, 0		; Verificamos bandera
    GOTO    MODOEA1
    GOTO    MODOEA0
    
MODOEA1:
    BTFSC   MODOEA, 1
    GOTO    OPERAR_H2
    GOTO    OPERAR_M2
    
MODOEA0:
    BTFSC   MODOEA, 1
    GOTO    OPERAR_H1
    GOTO    OPERAR_M1
    
OPERAR_H2:
    BCF MODOEA,0
    BCF MODOEA,1
    RETURN
    
OPERAR_M2:
    BCF MODOEA,0
    BSF MODOEA,1
    RETURN
    
OPERAR_H1:
    BSF MODOEA,0
    BSF MODOEA,1
    RETURN
    
OPERAR_M1:
    BSF MODOEA,0
    BCF MODOEA,1
    RETURN

INC_RELOJ:
    BTFSC MODOIP, 0
    RETURN
    
    BTFSC   MODOEA, 0		; Verificamos bandera
    GOTO    INCEA1
    GOTO    INCEA0
    
    INCEA1:
    BTFSC   MODOEA, 1
    GOTO    INCH2
    GOTO    INCM2
    
    INCEA0:
    BTFSC   MODOEA, 1
    GOTO    INCH1
    GOTO    INCM1
      
INCM1:
    INCF  CONTM1
    MOVF CONTM1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF CONTM1
    RETURN
      
INCM2:
    BANKSEL PORTA
    INCF  CONTM2
    MOVF CONTM2, W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF CONTM2
    RETURN
     
INCH1:
    INCF  CONTH1
    MOVF CONTH1, W
    SUBLW 4; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTH1
    RETURN
    
INCH2:
    INCF  CONTH2
    MOVF CONTH2, W
    SUBLW 3; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTH2
    RETURN  
 
DEC_RELOJ:
    BTFSC MODOIP, 0
    RETURN
    
    BTFSC   MODOEA, 0		; Verificamos bandera
    GOTO    DECEA1
    GOTO    DECEA0
    
    DECEA1:
    BTFSC   MODOEA, 1
    GOTO    DECH2
    GOTO    DECM2
    
    DECEA0:
    BTFSC   MODOEA, 1
    GOTO    DECH1
    GOTO    DECM1
      
DECM1:
    MOVF CONTM1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9
    MOVWF CONTM1
    RETURN
    DECF  CONTM1
    RETURN
      
DECM2:
    MOVF CONTM2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 5
    MOVWF CONTM2
    RETURN
    DECF  CONTM2
    RETURN
     
DECH1:
    MOVF CONTH1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 3
    MOVWF CONTH1
    RETURN
    DECF  CONTH1
    RETURN
    
DECH2:
    MOVF CONTH2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 3
    MOVWF CONTH2
    RETURN
    DECF  CONTH2
    RETURN

END
