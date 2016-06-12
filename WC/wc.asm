;********************************************************
;* Instituto Tecnológico de Costa Rica                	*
;* Escuela de Computación                               *
;* Arquitectura de Computadores                         *
;* Archivo: wc.asm (Word Count Function)  				*
;* Profesor: Erick Hernandez                            *
;* Estudiantes: Liza Chaves 2013016573                  *
;* 				Marisol González 2014160604				*
;* 				Izcar Muñoz 2015069773					*
;********************************************************


; include macros library
;**********************************************************************

%include 'macros.mac'



; section containing initialized data
;**********************************************************************

section .data
	;; numeric constants
	MAX_FILE_SZ equ 2048 
	;; two dots
	DOTS db ':'
	;; new line
	NEW_LINE db 10
	cantidad_lineas: db 10, 'Cantidad de líneas: '
		.len: equ $-cantidad_lineas
	cantidad_bytes: db 10, 'Cantidad de bytes: '
		.len: equ $-cantidad_bytes
	cantidad_palabras: db 10, 'Cantidad de palabras: '
		.len: equ $-cantidad_palabras
	cambio_linea: db 10
		.len: equ $-cambio_linea

section .bss
	in_file resb MAX_FILE_SZ
	line resb linelen
	line2 resb linelen 
	linelen equ 1000
	MATRIZ: resb MATRIZLEN 	;matriz donde se iran almacenando todas las lineas 
						    ;en orden alfabetico 
	MATRIZLEN equ 1000000
	MatrizMax equ 1000		; tamaño de cada linea de la matriz 
	strNum resb strNumlen
	strNumlen equ 3
	bandera resb 1
	contador equ 1024
	


;; **********************************************************************
;; section containing code
;; **********************************************************************
section .text
	global _start
_start:
	input_file:
		read in_file, MAX_FILE_SZ
		xor r10, r10 ; posicion de la matriz
		call ProcesarArchivo
		write cantidad_lineas, cantidad_lineas.len
		mov rsi, r13
		clean_buffer strNum
		call itoa
		write strNum, strNumlen
		write cantidad_bytes, cantidad_bytes.len
		mov rsi, r8
		clean_buffer strNum
		call itoa
		write strNum, strNumlen
		write cantidad_palabras, cantidad_palabras.len
		mov rsi, r14
		clean_buffer strNum
		call itoa
		write strNum, strNumlen
		write cambio_linea, cambio_linea.len
		write cambio_linea, cambio_linea.len
		
			
	exit

		 
	ProcesarArchivo:

		mov r9, rax
		xor r8, r8 ; posiicion de lectura de in_file
		xor rax, rax
		xor r13,r13 ; lineas
		xor r14, r14 ; palabras
		xor r12, r12 ; tendra todas las lineas que hay en la matriz 
		xor r10, r10 ; fila actual en al cual se encuentra al matriz 
		cmp r9, 0
		if e 
			ret
		endif 
		read_line:
			xor rcx, rcx 
			cmp r8, r9 
			if e 
			ret
			endif 
			removerBlancos:
				cmp rcx, 0
				if e 
					xor rax, rax
					mov al , [in_file + r8]
					cmp al, 32 ; espacio en blanco 
					if e 
						inc r8 ; incrementara para seguir con el siguiente elemento del archivo 
						jmp removerBlancos
					endif

					cmp al, 9 ; espacio en blanco 
					if e 
						inc r8 ; incrementara para seguir con el siguiente elemento del archivo 
						jmp removerBlancos

					else
						cmp al, 10
						if e
							mov [line + rcx], al
							inc r8
							inc r13
							cmp r8, r9 
							if e 
								ret
							endif
							jmp agregarMatriz
						endif
								
							mov [line + rcx], al
							inc rcx
							inc r8	
							jmp removerBlancos
					endif
				else 
					xor rax, rax
					mov al , [in_file + r8]
					cmp al, 32 ; espacio en blanco 
					if e 
						xor rbx, rbx
						mov bl , [in_file + r8 + 1]
						cmp bl, 32 ; espacio en blanco 
						if e 
							inc r8
							jmp removerBlancos
						endif

						cmp bl, 9 ; espacio en blanco 
						if e 
							inc r8
							jmp removerBlancos

						else 
							cmp bl, 10
							if e
								
								mov [line + rcx], bl
								inc r8
								cmp r8, r9 
								if e 

									ret
								endif
								jmp agregarMatriz
							endif
									
								mov [line + rcx], al
								inc rcx
								inc r8	
								jmp removerBlancos
						endif
					endif


					cmp al, 9 ; espacio en blanco 
					if e 
						xor rbx, rbx
						mov bl , [in_file + r8 + 1]
						cmp bl, 9 ; espacio en blanco 
						if e 
							inc r8
							jmp removerBlancos
						endif

						cmp bl, 32 ; espacio en blanco 
						if e 
							inc r8
							jmp removerBlancos
						else 
							cmp bl, 10
							if e
								
								mov [line + rcx], bl
								inc r8
								cmp r8, r9 
								if e 
									ret
								endif
								jmp agregarMatriz
							endif
									
								mov [line + rcx], al
								inc rcx
								inc r8	
								jmp removerBlancos
						endif
					

					else 
							cmp al, 10
							if e
								mov [strNum] , al 

								inc r13
								mov [line + rcx], al
								inc r8
								write strNum, strNumlen
								cmp r8, r9 
								if e 
									jmp agregarMatriz
								endif
								
							
							else 		
								mov [line + rcx], al
								inc rcx
								inc r8	

								jmp removerBlancos
							endif 
					endif
				endif 


			
			
	agregarMatriz:
		xor rcx, rcx
		mov rdi, r10
			
		auxAgregarMatriz:
			mov al, [line + rcx]
			cmp al, 10 ; comparacion de cambio de linea 
			if e 
				cmp rcx, 0 ; esto quiere decir que en line solo existe el cambio de linea entonces
							; no se tomara en cuenta enla matriz 
				if e 
					jmp read_line
				endif
				mov byte [MATRIZ + rdi], al
				add r10, MatrizMax
				inc r12 ; cantidad de lineas en al matriz jijijijjijijiji
				inc r14
				jmp read_line
			endif 
			mov byte [MATRIZ + rdi], al
			inc rcx
			inc rdi
			cmp al, 9
			if e 
				inc r14
				jmp auxAgregarMatriz 
			endif

			cmp al, 32
			if e 
				inc r14
				jmp auxAgregarMatriz 
			endif
			jmp auxAgregarMatriz 

			
			
		



itoa:
	push rcx
	push rax
	push rbx 
	mov rcx, 3;Len del buffer del caracter
	mov rax, rsi ;Número en entero
	mov rbx, 10 
	
	convert:
		xor rdx, rdx
		div rbx    ;Divide rax/rbx, en dl (rdx) queda el residuo de la división
		add dl, '0'  ;Se convierte en caracter el número
		mov [strNum + rcx - 1], dl ;Se añade el caracter en la última posición

		dec rcx ;Se una posición a la izquierda del buffer
		cmp rax, 0 ;Sí el cociente es 0, ya terminó de dividir el número
		jne convert  ;Sino, siga iterando
		
		pop rbx
		pop rax
		pop rcx

		ret
