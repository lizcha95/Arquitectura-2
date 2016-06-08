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
	MAXIMO equ 2048
	len equ 100
	nuevaLinea	db 0xa	

	errorParam0: db 10, 'Error: No se han ingresado parametros', 10, 10
		.len: equ $-errorParam0
	errorParam1: db 10, 'Error: faltan parámetros por ingresar', 10, 10
		.len: equ $-errorParam1

section .bss

	numero resb 2048

	parametro: resb parametroLen
	parametroLen equ 100

	archivo: resb archivoLen
	archivoLen equ 100

section .text
global	_start

_start:

;**********************************************************************************
;
; guardar: Lee los argumentos de la consola y guarda el nombre del archivo en el buffer archivo y
; 		   los parámetros en el buffer parametro
;
;**********************************************************************************

guardar:
	; Guarda el número de argumentos de la pila en r8
	pop	r8
	; Guarda el nombre del ejecutable en r15 (No lo necesitaremos)
	pop r15
	; Resta 1 a r8 dado a que el nombre del ejecutable se cuenta como un argumento
	;dec r8
	; Creamos el contador de arumentos de la pila
	mov r9, 0
	;Comparamos r8 con cero, para verificar si hay argumentos
	cmp r8, 0
	if e
		write errorParam0, errorParam0.len
		exit
	else
		cmp r8, 1
		if e
			write errorParam1, errorParam1.len
			exit
		endif
	endif

	; Ciclo que itera cada argumento
	loop:
		inc r9
		; Compara r9 con r8 a ver si ya llegó al final de los argumentos
		cmp r8, r9
		if e
			write archivo, archivoLen
			write nuevaLinea, 1
			write parametro, parametroLen
			write nuevaLinea, 1
			exit
		endif

	; Saca el argumento a revisar
	argumentos:
		pop rsi

	cmp r9, 1
	if e
		call guardarArchivo
	else
		call guardarArg
	endif

	jmp loop

	; Se guada el nombre del archivo de texto en el buffer archivo
	guardarArchivo:

		push rbx
		push rsi
		push rax

		mov rbx, 0
		.archivo_loop:
			cmp byte [rsi+rbx], 0
			je .archivo_exit
			mov al, [rsi+rbx]
			mov [archivo+rbx], al
			inc rbx
			jmp .archivo_loop

		.archivo_exit:
			pop rax
			pop rsi
			pop rbx		
			ret

	; Se guarda los argumentos en el buffer argumento
	guardarArg:

	;;TODO: HACER QUE EL BUFFER NO SE LIMPIE SOLO (NO ACTUALIZAR EL CONTADOR DE ALGUNA MANERA)

		push rbx
		push rsi
		push rax

		mov rbx, 0
		.arg_loop:
			cmp byte [rsi+rbx], 0
			je .arg_exit
			mov al, [rsi+rbx]
			mov [parametro+rbx], al
			inc rbx
			jmp .arg_loop

		.arg_exit:
			pop rax
			pop rsi
			pop rbx
			ret

	itoa:
		push rax
		push rcx
		push rdx

		mov rcx, 2047
		mov rax, r10
		
		loop_itoa:
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
				jmp loop_itoa
			endif