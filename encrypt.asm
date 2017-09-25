SECTION .data
	msg_get_key			db "[Viginere encryption] Enter your key: ", 0
	msg_get_key_len		equ $ - msg_get_key
	msg_done			db "[Viginere encryption] Encryption complete ",0xa
	msg_done_len		equ $ - msg_done

	input				db "./plain_text.txt",0
	output				db "./cipher_text.txt",0

	termios:	times 36 db 0
	ICANON:		equ 1<<1
	ECHO:		equ 1<<3
	sys_exit	equ 1
	sys_read	equ 3
	sys_write	equ 4
	sys_open	equ 5
	sys_close	equ 6
	stdin		equ 0
	stdout		equ 1


SECTION .bss
	plain_text:	resb 1024
	buffer:		resb 1024
	key:		resb 1024

;##########################################################
;MAIN
;##########################################################

SECTION .text
global _start

_start:
	;print hello
	mov eax, sys_write
	mov ebx, stdout
	mov ecx, msg_get_key
	mov edx, msg_get_key_len
	int 80h

	call get_key
	
	; open input file
	mov eax, sys_open	; 5 open
	mov ecx, stdin		; 0 read-only
	mov ebx, input		; filename 
	int 80h

	; read from file
	mov ebx, eax
	mov eax, sys_read	; 3 read
	mov ecx, plain_text 
	mov edx, 1024
	int 80h
	
	; open output file
	mov eax, sys_open
	mov ecx, stdout	; write-only
	mov ebx, output
	int 80h

	mov edi, eax
	mov esi, plain_text
	mov edx, key
	call encryption

	; print finish
	mov eax, sys_write
	mov ebx, stdout
	mov ecx, msg_done
	mov edx, msg_done_len
	int 80h

	; close files
	mov eax, sys_close
	int 80h
	
	; exit
	mov eax, 1
	mov ebx, 0
	int 80h

;##########################################################
;ENCRYPTION
;##########################################################

; edi - output file
; eax - plain_text char
; ebx - key char
encrypt_char:
	.start:
		push edx
		xor edx,edx

		cmp eax, byte 10
		je .new_line

		add eax, ebx
		sub eax, 64

		mov ebx, 95
		div ebx
		add edx, 32

	.write:
		mov [buffer], edx
		mov eax, sys_write
		mov ebx, edi
		mov ecx, buffer
		mov edx, 1
		int 80h

		pop edx
		ret

	.new_line:
		mov edx, eax
		jmp .write

; edi - output file
; esi - plain_text
; edx - key
encryption:
	.start:
		xor eax, eax
		xor ebx, ebx

	.next_symbol:
		mov al, [esi]
		mov bl, [edx]

		call encrypt_char

		inc esi
		inc edx

		cmp [esi], byte 0	; end of text
		je .exit
		cmp [edx], byte 0	; end of key
		je .reset_key

		jmp .next_symbol

	.reset_key:
		mov edx, key
		jmp .next_symbol

	.exit:
		mov [buffer], byte 10

		mov eax, sys_write
		mov ebx, edi
		mov ecx, buffer
		mov edx, 1
		int 80h

		ret


;##########################################################
;PASSWORD INPUT
;##########################################################

canonical_off:
	call read_stdin_termios

	; clear canonical bit in local mode flags
	mov eax, ICANON
	not eax
	and [termios+12], eax

	call write_stdin_termios
	ret

echo_off:
	call read_stdin_termios

	; clear echo bit in local mode flags
	mov eax, ECHO
	not eax
	and [termios+12], eax

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
		mov eax, sys_read	; 3
		mov ebx, stdin		; 0
		mov ecx, buffer
		mov edx, 1			; length
		int 80h
		
		cmp [ecx], byte 10	; \n
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
		mov edx, 1			; length
		int 80h

		jmp .next_symbol

	.stop_read:
		mov [edi], byte 0	; add endline
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
		mov  edx, 3			; length
		int  80h

		sub edi, 1
		dec esi

		jmp .next_symbol

get_key:
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