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

section .data

	; Mensajes de error.
	errorArg db 10, 'Argumento invalido.', 10, 10
		.len: equ $ - errorArg 

	errorCantArgs db 10, 'Cantidad invalida de argumentos.', 10, 10
		.len: equ $ - errorCantArgs

	; Nueva linea.
	nuevaLinea db 10
		.len: equ $ - nuevaLinea

section .bss
	; Tamanos definidos para archivos, buffers, 
	; nombre de archivo y delimitador.
	MAXIMO equ 2048
	TAM_NOM_ARCHIVO equ 64
	TAM_DELIM equ 200
	MIN_CANT_ARGS equ 4

	; Buffers y tamanos.
	in_file: resb MAXIMO
	out_buffer: resb MAXIMO
	format_buffer: resb MAXIMO

	; Buffer para nombre del archivo.
	nomArchivo: resb TAM_NOM_ARCHIVO

	; Buffer para delimitador.
	delim: resb TAM_DELIM

	; Bandera para indicar final de archivo.
	fin_buffer: resb 1

section .text
	global _start
	_start:
		call leerArgs
		call scanArchivo
		exit
		
	; ***************************************************
	; Seccion de analisis de argumentos:
	; ***************************************************
	; r12: Puntero a direccion del parametro en stack.
	; r13: Puntero a inicio de buffer con parametro.
	; r14: Contador para buffer de parametro.
	; rcx: Indice para recorrer parametros.
	; rax: Caracter siendo analizado.
	; rdx: Contador para buffer del parametro.
	; rsi: Contador para buffer del formato.
	;****************************************************

	leerArgs:
		; Se recuerdan posiciones que ocupan en el stack.
		push r12 ; Posicion: 16
		push r13 ; Posicion: 24
		push r14 ; Posicion: 32
		push rcx ; Posicion: 40
		push rax ; Posicion: 48
		push rdi ; Posicion: 56
		push rdx ; Posicion: 64
		push rsi ; Posicion: 72


		xor r14, r14

		mov	r12, rsp 		; Mueve direccion de stack a r12.
		add r12, 72			; Mueve 8 bytes
		mov	rcx, [r12]		; Mueve numero de param a rcx.
		cmp	rcx, MIN_CANT_ARGS 	; Si hay menos de cuatro parametros, error.
		jb exitNoArgs

		add r12, 8 			; Se mueve una posicion en stack.
		dec rcx 			; Disminuye numero de parametros.
		leerArgs.param:
			cmp	rcx, 0		; Si es el ultimo parametro
			if e
				jmp	leerArgs.abrir 	; Abre archivo.
			else
				add	r12, 8		; Incrementar puntero en stack.
				dec	rcx				; Reducir el numero de parametros.
				jmp	leerArgs.scan 		; Va a revisar parametros.
			endif

		leerArgs.scan:
			mov	r13, [r12] 		; Mueve posicion de parametros a r13.
			xor rdx, rdx 		; Indice de posiciones.
			leerArgs.scanStart:
				mov al, [r13 + rdx] 
				cmp	al, 45      ; Compara primer caracter con '-'.
				je  leerArgs.scanParam ; Si es igual, va a revisar delim y formato.
				jmp leerArgs.scanNomArchivo ; Si no, revisa nombre de archivo.
			
		leerArgs.scanParam:
			inc rdx
			mov al, [r13 + rdx]
			cmp al, 100				; Compara caracter con 'd'.
			if e
				jmp leerArgs.scanDelim 		; Si es igual, verifica delimitador.
			else
				cmp al, 102				; Si no, compara con 'f'.
				if e
					jmp leerArgs.scanFormat		; Si es igual, verifica formato.
				else
					jmp exitInvArgs
				endif
			endif

		leerArgs.scanNomArchivo:
			mov al, [r13 + rdx] 		; Mueve siguiente caracter.
			cmp	al, 0	        ; Si encuentra final de parametro, vuelve.
			if e
				jmp  leerArgs.param
			else
				mov [nomArchivo + r14], al  ; Si no, mueve a buffer de nombre de archivo.
				inc rdx 				; Incrementa contadores.
				inc r14
				jmp leerArgs.scanNomArchivo  ; Repite ciclo.
			endif

		leerArgs.scanDelim:
			inc rdx
			mov al, [r13 + rdx] 		; Mueve siguiente caracter.
			cmp al, 0 			; Si no encuentra caracteres, error.
			if e
				jmp exitNoArgs
			else
				xor rsi, rsi 			; Contador.
				scanDelim.loop:
					mov [delim + rsi], al ; Mueve caracter a delimitador.
					inc rdx 
					mov al, [r13 + rdx] 	; Mueve siguiente caracter.
					cmp al, 0
					if e
						inc rsi 			; Incrementa contador.
						mov [delim + rsi], al ; Mueve ultimo caracter.
						jmp leerArgs.param 		; Vuelve a ciclo principal.
					else
						inc rsi
						jmp scanDelim.loop ; Sino, continua guardando delimitador.
					endif			
			endif

		; Ciclo para guardar el formato del buffer de salida.
		leerArgs.scanFormat:
			xor rsi, rsi 			; Contador.
			scanFormat.loop:
				inc rdx
				mov al, [r13 + rdx]
				cmp al, 0 		; Si proximo caracter es nulo, termina de guardar formato.
				if e
					mov byte[format_buffer + rsi], 0	; Agrega caracter nulo al final de formato.
					je leerArgs.param
				else
					mov [format_buffer + rsi], al ; Sino, guarda en buffer de formato.
					inc rsi
					jmp scanFormat.loop ; Repite ciclo.
				endif
			scanFormat.end:
	
	; Escribe error en caso de que la cantidad de args sea incorrecta.	
	exitNoArgs:
		write errorCantArgs, errorCantArgs.len
			pop rsi
			pop rdx
			pop rdi
			pop rax
			pop rcx
			pop r14
			pop r13
			pop r12
			exit

	; Escribe error en caso de que el formato de los parametros sea incorrecto.
	exitInvArgs:
		write errorArg, errorArg.len
			pop rsi
			pop rdx
			pop rdi
			pop rax
			pop rcx
			pop r14
			pop r13
			pop r12
			exit

		leerArgs.abrir:
			mov byte[nomArchivo + r14], 0	; Mueve caracter nulo para determinar final de nombre de archivo.

			mov rax, 2 				; Codigo para abrir archivo en modo read only.
			mov rdi, nomArchivo
			mov rsi, 0
			mov rdx, 0644 			; Flags
			syscall 				; File handler queda en rax.

			leer_archivo:
				mov rdi, rax 		; FH de archivo en rax.
				mov rax, 0		 	; stdin.
				mov rsi, in_file
				mov rdx, MAXIMO
				syscall

			; Cerrar archivo.
			cerrar_archivo:
				mov rax, 3
				mov rdi, rax
				syscall

		pop rsi
		pop rdx
		pop rdi
		pop rax
		pop rcx
		pop r14
		pop r13
		pop r12
		ret 			; Termina proceso de analizar parametros.

		
	; ***************************************************
	; Seccion de formato de salida:
	; ***************************************************
	; Registros
	; r8: Indice principal dentro del archivo.
	; r9: Indice principal para buffer de salida.
	; r10: Contador de posiciones en el stack.
	; r11: Guarda numero.
	; r12: Indice para recorrer pila.
	; r15: Flag de final de archivo.
	; rcx: Indice para recorrer archivo de entrada,
	; rax: Guarda caracter siendo analizado.
	; rdx: Indice para recorrer buffer de formato guardado.
	; ***************************************************
	
	scanArchivo:
		; Guardar registros utilizados en la pila.
		push rdx
		push rcx
		push rbx
		push rax
		push r8
		push r9
		push r10
		push r11
		push r12
		push r13

		; Limpiar contadores.
		xor rcx, rcx
		xor r8, r8

		; Recomienza contadores para proxima linea.
		scanArchivo.proxLinea:
			xor r10, r10
		scanArchivo.loop:
			; Analiza primer caracter de archivo.
			mov al, [in_file + rcx]
			; Si es nulo, cambia bandera de fin de buffer.
			cmp al, 0
			if e
				; Cambia bandera.
				mov byte [fin_buffer], 1
				jmp scanArchivo.nuevaLinea
			else
				xor rbx, rbx
				push rcx
				push rax
				; Ciclo para encontrar el delimitador.
				loop.scanDelim:
					; Si encuentra nulo, termina ciclo.
					cmp byte [delim + rbx], 0
					if e
						pop rax
						pop rcx
						; Agrega direccion a total de direcciones en stack.
						add rcx, rbx
						push r8
						inc r10
						mov r8, rcx
						jmp scanArchivo.loop
					; Sino, continua buscando delimitador.
					else
						mov al, [in_file + rcx]
						cmp al, [delim + rbx]
						; Si no lo encuentra, compara con cambio de linea.
						if ne
							pop rax
							pop rcx
							add rcx, rbx

							cmp al, 10	
							; Si es, salta a analizar nueva linea.
							if e
								jmp scanArchivo.nuevaLinea
							; Si no, sigue buscando delimitador.
							else
								inc rcx
								jmp scanArchivo.loop
							endif
						else
							inc rbx
							inc rcx
							jmp loop.scanDelim
						endif
					endif
			endif

		scanArchivo.nuevaLinea:
			; Guarda posicion dentro del archivo.
			push r8
			inc r10
			mov r13, r10

			; Contadores.
			xor rdx, rdx
			xor r9, r9

			; Ciclo para analizar cada linea del buffer.
			salida.formato:
				; Compara caracter con nulo.
				mov al, [format_buffer + rdx]
				cmp al, 0
				; Si es nulo, imprime.
				if e
					jmp salida.imprimir
				endif
				; Sino, compara caracter con #(indica argumentos).
				cmp al, 35
				if e
					jmp salida.buscar
				endif
				; Sino, compara caracter con / (para escapar $)
				cmp al, 92
				if e
					jmp salida.escapar
				endif
				; Sino, mueve caracter a buffer de salida y continua analizando.
				mov [out_buffer + r9], al
				inc rdx
				inc r9
				jmp salida.formato

			; Ciclo para incluir caracteres escapados.
			salida.escapar:
				inc rdx
				mov al, [format_buffer + rdx]
				; Compara caracter con nulo.
				cmp al, 0
				; Si es nulo, imprime linea.
				if e
					jmp salida.imprimir
				endif
				; Si no, incluye caracter y sigue analizando buffer.
				mov [out_buffer + r9], al
				inc rdx
				inc r9
				jmp salida.formato

			; Ciclo para encontrar todos los caracteres que pertenecen a una columna.
			salida.buscar:
				; Contador.
				xor r11, r11
				inc rdx
				mov al, [format_buffer + rdx]
				; Compara caracter con nulo.
				cmp al, 0
				if e
					; No encuentra mas columnas en linea.
					jmp salida.noMasArgs
				else
					; Busca caracter indicador de nueva columna.
					cmp al, 35
					if e
						; Si es igual, agrega caracter a columna.
						mov [out_buffer + r9], al
					else
						; Sino, compara para verificar si es numero.
						cmp al, 49
						jb salida.argsError
						cmp al, 57
						ja salida.argsError
					endif
				endif

				; Ciclo para buscar numeros de argumentos en el buffer de formato.
				buscar.numero:
					sub al, 48
					add r11, rax
					inc rdx
					; Si ya no encuentra mas digitos, sale del ciclo.
					cmp byte [format_buffer + rdx], 49
					jb buscar.continuar
					cmp byte [format_buffer + rdx], 57
					ja buscar.continuar

					; Sino, sigue buscando digitos.
					shr r11, 3
					add r11, rax
					add r11, rax

					mov al, [format_buffer+rdx]
					jmp buscar.numero

				buscar.continuar:
					; Busca argumento en la pila.
					mov r10, r13
					cmp r11, r10
					; Si ya esta, sale del ciclo.
					ja salida.formato

					; Si no, agrega direccion a la pila.
					mov r12, rsp

					prep:
						; Ciclo se termina.
						cmp r10, 0
						if ne
							; Agrega posiciones a la pila.
							add r12, 8
							dec r10
							jmp prep
						endif

				; Aumenta cantidad de posiciones en stack.
				buscar.loop:
					cmp r10, r11
					if ne
						sub r12, 8
						inc r10
						jmp buscar.loop
					endif		


				; Pasa buffer a formato de salida.
				buscar.pasarASalida:
					; Pasa indice de pila a r12.
					mov r12, [r12]
					pasarASalida.loop:
						mov al, [in_file + r12]
						; Compara con nulo.
						cmp al, 0
						; Si es igual, vuelve a ciclo de analisis.
						if e
							jmp salida.formato
						; Sino, compara con cambio de linea.
						else
							cmp al, 10
							; Si es igual, vuelve a ciclo de analisis.
							if e
								jmp salida.formato
							else
								xor rbx, rbx
								push r12
								push rax
							endif
						endif

						; Ciclo para pasar todos los caracteres del delimitador.
						pasarASalida.loop.scanDelim:
							; Si es nulo, sale del ciclo.
							cmp byte[delim + rbx], 0
							if e
								pop rax
								pop r12
								jmp salida.formato
							else
								; Sino, compara con delimitador.
								mov al, [in_file + r12]
								cmp al, [delim + rbx]
								; Si no es delimitador, mueve caracter y continua analizando linea.
								if ne
									pop rax
									pop r12
									mov [out_buffer + r9], al
									inc r9
									inc r12
									jmp pasarASalida.loop
								; Si es, pasa a ciclo especial para delimitador.
								else
									inc rbx
									inc r12
									jmp pasarASalida.loop.scanDelim
								endif
							endif

			; Ciclo para cuando no se encuentran suficientes columnas en linea.
			salida.argsError:
				mov [out_buffer + r9], al
				inc rdx
				inc r9
				jmp salida.formato

			; Ciclo para cuando no quedan mas argumentos en el formato.
			salida.noMasArgs:
				mov [out_buffer + r9], al
				jmp salida.imprimir

			; Imprime la linea en formato de salida.
			salida.imprimir:
				mov byte [out_buffer + r9], 10
				inc r9
				write out_buffer, r9

			; Ciclo para limpiar la pila despues de imprimir la linea.
			limpiarStack:
				; r13 funciona como el r10.
				; Si no quedan mas posiciones en el stack, verifica que sea ultima linea.
				cmp r13, 0
				if e
					; Verifica que sea ultima linea del buffer.
					cmp byte [fin_buffer], 1
					; Si es, retorna.
					if e
						pop r13
						pop r12
						pop r11
						pop r10
						pop r9
						pop r8
						pop rax
						pop rbx
						pop rcx
						pop rdx
						ret
					endif
				; Si quedan mas posiciones, sigue limpiando stack.
				else
					pop r8
					dec r13
					jmp limpiarStack
				endif

			; Incrementa posiciones en archivo de entrada.
			inc rcx
			mov r8, rcx
			jmp scanArchivo.proxLinea