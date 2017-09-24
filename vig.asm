SECTION .data
    msg_get_key 		db "Enter your key: ", 0
    msg_get_key_len 	equ $ - msg_get_key

	input 		db "./input.txt",0
	output 		db "./output.txt",0


	sys_exit    equ 1
    sys_fork    equ 2
    sys_read    equ 3
    sys_write   equ 4
    sys_open    equ 5
    sys_close   equ 6
    stdin       equ 0
    stdout      equ 1

	termios:        times 36 db 0
    ICANON:         equ 1<<1
    ECHO:           equ 1<<3


SECTION .bss
	plain_text: 	resb 1024
	buffer: 		resb 1024
	key: 			resb 1024


;##########################################################
;MAIN
;##########################################################

SECTION .text
global _start

_start:

	call get_key
	


	;OPEN INPUT FILE
;  	mov eax, sys_open  	; 5 open
;   mov ecx, stdin  	; 0 read-only
;	mov ebx, input 		;filename 
;   int 80h

	;READ FROM FILE
;	mov eax, sys_read  	; 3 read
;    mov ebx, eax	
;   	mov ecx, plain_text 
;	mov edx, 1024    
;   	int 80h     
	
	;OPEN OUTPUT FILE
;	mov eax, sys_open
;	mov ecx, sys_write	;write-only
;	mov ebx, output
;	int 80h

;	call _encryption

	;PRINT     
;	 mov eax, sys_write 
;    mov ebx, stdout
;    mov ecx, plain_text 
;    mov edx, 1024   
;    int 80h   

	;CLOSE FILE
;	mov eax, sys_close
;	int 80h
	
	;EXIT
	mov eax, 1
	mov ebx, 0
	int 80h


;##########################################################
;ENCRYPTION
;##########################################################

;esi - plain_text
;edx - key





;##########################################################
;PASSWORD INPUT
;##########################################################

canonical_off:
    	call read_stdin_termios

    	; clear canonical bit in local mode flags
        ;push rax
    	mov eax, ICANON
   		not eax
        and [termios+12], eax
        ;pop rax

        call write_stdin_termios
        ret

echo_off:
        call read_stdin_termios

        ; clear echo bit in local mode flags
        ;push rax
        mov eax, ECHO
        not eax
        and [termios+12], eax
        ;pop rax

        call write_stdin_termios
        ret

canonical_on:
        call read_stdin_termios

        ; set canonical bit in local mode flags
        or dword [termios+12], ICANON

        call write_stdin_termios
        ret

echo_on:
        call read_stdin_termios

        ; set echo bit in local mode flags
        or dword [termios+12], ECHO

        call write_stdin_termios
        ret

read_stdin_termios:

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5401h
        mov edx, termios
        int 80h

        ret

write_stdin_termios:

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5402h
        mov edx, termios
        int 80h

        ret

;edi - key adress
read_string:
	.start:
		mov esi,0
	.next_symbol:

	    mov eax, sys_read 	; 3
	    mov ebx, stdin 		; 0
	    mov ecx, buffer
	    mov edx, 1			; length
	    int 80h
	    
	    cmp [ecx], byte 10  ; \n
	    jle .stop_read		; maybe mistake

		cmp [ecx], byte 127 ; del
	    je .backspace		; maybe mistake


	    mov eax, [buffer]
	    mov [edi], eax
	    add edi, 1
	    inc esi
	    

  		mov [buffer], byte 42	; *

	    mov eax, sys_write
	    mov ebx, stdout
	    mov ecx, buffer	
	    mov edx, 1         	; length
	    int 80h

	    jmp .next_symbol

	.stop_read:
	    
	    mov [edi], byte 10	; \n

	    ret

	.backspace:

		cmp esi, 0
		je .next_symbol
    
	    mov [buffer], byte 8			; backspace
	    mov [buffer + 1], byte 32		; space
	    mov [buffer + 2], byte 8		; backspace
	    
	    mov  eax, sys_write	
	    mov  ebx, stdout
	    mov  ecx, buffer
	    mov  edx, 3     ; length
	    int  80h

	    sub edi, 1
	    dec esi

	    jmp .next_symbol

get_key:

	mov eax, sys_write
    mov ebx, stdout
    mov ecx, msg_get_key
    mov edx, msg_get_key_len
    int 80h

    call canonical_off
    call echo_off

    mov edi, key
    call read_string

    call canonical_on
    call echo_on

    mov [buffer], byte 10	; \n
    mov eax, sys_write
    mov ebx, stdout
    mov ecx, buffer
    mov edx, 1
    int 80h 

    ret