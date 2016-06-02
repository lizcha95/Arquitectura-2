;********************************************************
;* Instituto Tecnológico de Costa Rica                	*
;* Escuela de Computación                               *
;* Arquitectura de Computadores                         *
;* Archivo: cut.asm (Cut Function)  					*
;* Profesor: Erick Hernandez                            *
;* Estudiantes: Liza Chaves 2013016573                  *
;* 				Marisol González 2014160604				*
;* 				Izcar Muñoz 2015069773					*
;********************************************************

; include macros library
%include 'macros.mac'

; section containing initialized data

section .data
	; Tamanio máximo
	MAXIMO equ 2048

	cantidad_lineas: db 10, 'Cantidad de líneas: '
		.len: equ $-cantidad_lineas
	cantidad_bytes: db 10, 'Cantidad de bytes: '
		.len: equ $-cantidad_bytes
	cantidad_palabras: db 10, 'Cantidad de palabras: '
		.len: equ $-cantidad_palabras
	cambio_linea: db 10
		.len: equ $-cambio_linea


; Sección datos no inicializados

section .bss
	in_file resb MAXIMO
	numero resb 2048

section .text

GLOBAL _start

_start:
	input_file:
		read in_file, MAXIMO
		; Guarda el número total de caracteres
		mov r9, rax
		; Verifica si archivo esta vacio.
		cmp r9, 0
		; Si esta vacio, salta a imprimir.
		if e
			jmp print
		endif
		; Índice para el buffer de caracteres (in_file)
		xor r8, r8
		; Contador de líneas
		xor r13, r13
		; Contador de Palabras
		xor r14, r14

	scan:
		; Verifica cuando hay una nueva palabra.
		cmp byte[in_file + r8], ' '
		if e
			inc r14
		endif

		; Verifica cuando hay una nueva línea.
		cmp byte[in_file + r8], 10
		if e
			cmp byte[in_file + r8 + 1], 10
			if e
				inc r13
			else
				inc r8
				cmp r8, r9
				if e
					inc r13
				else
					inc r13
					inc r14
				endif
				dec r8
			endif
		endif

	next:
		; Si llega al final del archivo, el programa termina
		cmp r8, r9		
		if e
			; Agrega ultima linea y palabra.
			inc r13
			inc r14
			jmp print
		else
			inc r8
			jmp scan
		endif

	print:
		write cantidad_lineas, cantidad_lineas.len
		mov r10, r13
		call itoa
		write cantidad_bytes, cantidad_bytes.len
		mov r10, r8
		call itoa
		write cantidad_palabras, cantidad_palabras.len
		mov r10, r14
		call itoa
		write cambio_linea, cambio_linea.len
		write cambio_linea, cambio_linea.len
		exit

	itoa:
		push rax
		push rcx
		push rdx

		mov rcx, 2047
		mov rax, r10
		
		loop:
			xor rdx, rdx
			mov r15, 10
			div r15
			add dl, 30h
			mov byte[numero + rcx], dl
			dec rcx
			cmp rax, 0
			if e
				pop rdx
				pop rcx
				pop rax
				write numero, 2048
				clean_buffer numero
				ret
			else
				jmp loop
			endif
