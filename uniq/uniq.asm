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

;**********************************************************************
; Incluir Librerías
;**********************************************************************

%include 'macros.mac'

;**********************************************************************
; Datos Inicializados
;**********************************************************************
section .data
	; Máximo tamaño del archivos
	MAX_FILE_SZ equ 1000000

	cambio_linea: db 10
		.len: equ $-cambio_linea

	errorParam0: db 10, 'Error: No se han ingresado parametros', 10, 10
		.len: equ $-errorParam0


section .bss

	MatrizOrdenar: resb MAX_FILE_SZ
	line: resb linelen
	line2: resb linelen
	lineAux: resb linelen
	auxBufferLine: resb MAX_FILE_SZ
	auxBufferLine2: resb MAX_FILE_SZ
	auxBufferLine3: resb MAX_FILE_SZ

	in_file resb MAX_FILE_SZ
	linelen equ 1000
	MATRIZ: resb MATRIZLEN 	;matriz donde se iran almacenando todas las lineas 
				    ;en orden alfabetico 
	MATRIZLEN equ 1000000
	MatrizMax equ 1000		; tamaño de cada linea de la matriz 
	strNum resb strNumlen
	strNumlen equ 3
	bandera resb 1
	contador equ 1024
	numero resb 2048
	archivo: resb archivoLen
	archivoLen equ 100

	argN: resq 1
	args: resb 2000
	argDir: resq 10

section .text
	global _start:

_start:

		; Guarda el número de argumentos de la pila en r8
		pop	r8
		; Guarda el nombre del ejecutable en r15 (No lo necesitaremos)
		pop r15

		;Comparamos r8 con cero, para verificar si hay argumentos
		cmp r8, 0
		if e
			write errorParam0, errorParam0.len
			exit
		endif

		; saca el nombre del archivo a revisar
		pop rsi

		; Función para agarrar el nombre del archivo de la línea de comandos
		call guardarArchivo

		; Se abre el archivo
		mov rax, 2
		mov rdi, archivo ;el nombre del file tiene que ser terminado con un 0
		mov rsi, 0 ; 0 es read only
		mov rdx, 0644 ;flags	
		syscall

		mov rdi, rax ; el file handle
		mov rax, 0 ; para leer input
		mov rsi, in_file
		mov rdx, MAX_FILE_SZ
		syscall
		push r15
		push r8

		mov r8, rax

		mov rax, 3
		mov rdi, rax
		syscall

		xor r10, r10
		call proceso
		call final

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

proceso:
		xor rcx, rcx 	;contador
		xor rdx, rdx
		xor rbx, rbx
		xor r10, r10
		xor r11, r11
		xor r12, r12    ;wordLen
		xor r13, r13 	;contado para agregar a palabrasd
		xor r15, r15	;len linea 2
		xor r14, r14  	;len linea 1
		xor r9, r9
		xor rsi, rsi
		xor rdi, rdi

	; resultado en la pila 

		mov r12, r8
		mov rbp, rsp

		call OrdenarMAtrizOUT

		prints:
			mov rsp, rbp
			call clearLine
			call clearLine2

			print:
				write MATRIZ, MAX_FILE_SZ

		xor rcx, rcx 	;contador
		xor rdx, rdx
		xor rbx, rbx
		xor r10, r10
		xor r11, r11 ;wordLen
		xor r13, r13 	;contado para agregar a palabrasd
		xor r15, r15	;len linea 2
		xor r14, r14  	;len linea 1
		xor r9, r9

			
			exit1:
			 	exit

	; SE LIMPIAN TODOS LOS BUFFERS

	OrdenarMAtrizOUT:

	;Limpia todos los registros totalmente par aque no haya nada mal
		xor r13, r13 	;contado para agregar a palabrasd
		xor r15, r15	;len linea 2
		xor r14, r14  	;len linea 1
		xor r9, r9
		xor rsi, rsi
		xor rdi, rdi

		; se limpia todas las entradas ya que no hay duplicados

		xor rcx, rcx 	;contador
		xor rdx, rdx
		xor rbx, rbx
		xor r10, r10
		xor r11, r11
		call getline ; se consiguen las lineas a evealuar
		call getline2 ; se consiguen las lineas a evaluar 

		jmp compararLineBuffer ; se comienza el las comparaciones 

	final:
		pop rbx
		pop rax
		pop rdx
		pop rcx

		cmp rdi, 1
		jge cicloPadre
		call ProcesarArchivo
		jmp prints

	cicloPadre:
		xor rcx, rcx 	;contador
		xor rdx, rdx
		xor rbx, rbx
		xor r10, r10
		xor r11, r11
		xor r13, r13 	;contado para agregar a palabrasd 	;repetir hasta que no se haga cambios
		xor r15, r15	;len linea 2
		xor r14, r14  	;len linea 1
		xor r9, r9
		xor rsi, rsi
		xor rdi, rdi

		call getline
		call getline2

		jmp compararLineBuffer

	getline:
		call clearLine
		mov r9, rcx
		push rdx
		xor rdx, rdx
		xor r14, r14 ;len de la linea

		loop1:
			xor rax, rax

			;se mueve a al el contenido del in_file y se compara con un espacio en blanco
			mov al, [in_file + rcx] 	
			;espacio en blanco 
			cmp al, 32 	
			;este se compara si es el CaracterMenor significa que es caracter especial 				  				
			jb .pass
			mov [line + rdx], al

			inc rcx
			inc r14
			inc rdx
		
			;se compara con un cambio de linea, mientras no sea, se sigue metien al buffer llamado linea
			cmp [in_file + rcx], byte 10
			if ne
				jmp loop1
			endif 

			pop rdx
			inc rcx
			mov r11, rcx 
			ret

		; Ignorar	
		.pass:
			cmp rcx, r12
			ja final

			inc rcx
			jmp loop1

	getline2:
		;meter la segunda linea al buffer llamado line2
		call clearLine2
		mov rsi, rcx
		push rdx
		xor rdx, rdx
		xor r15, r15
		loop2:
			xor rax, rax

			mov al, [in_file + rcx]
			cmp al, 32
			jb .pass
			mov [line2 + rdx], al

			inc rcx
			inc rdx
			inc r15

			cmp [in_file + rcx], byte 10

			if nbe
				jmp loop2
			endif

			pop rdx

			inc rcx
			mov r8, rcx

			ret
		.pass:
			cmp rcx, r12
			if a
			jmp final
			endif 
			
			inc rcx
			jmp loop2

	;metodos de comparacion
	clearLine:
		push rcx
		xor rcx, rcx

		clearLineLoop:
			cmp rcx, linelen
			je clearLineExit
			;Limpiar la primera linea
			mov [line + rcx], byte 0 
			inc rcx
			jmp clearLineLoop

		clearLineExit:
			pop rcx
			ret

	clearLine2:
		push rcx
		xor rcx, rcx

		clearLine2Loop:
			cmp rcx, linelen
			je clearLine2Exit
			;limpiar la segunda linea
			mov [line2 + rcx], byte 0 					
			inc rcx
			jmp clearLine2Loop

		clearLine2Exit:
			pop rcx
			ret

	clear_in_file:
		push rcx
		xor rcx, rcx

		clear_in_fileL:
			cmp rcx, MAX_FILE_SZ
			je clear_in_fileExit
			;limpiar el buffer de entrada
			mov [in_file + rcx], byte 0	
			inc rcx
			jmp clear_in_fileL

		clear_in_fileExit:
			pop rcx
			xor r10, r10
			ret

	limpiar_Buffer_:
		push rcx
		xor rcx, rcx

		limpiar_Buffer_Loop:
			cmp rcx, MAX_FILE_SZ
			je limpiar_Buffer_Exit
			;limpirar lo buffers auxiliares
			mov [auxBufferLine + rcx], byte 0 								
			inc rcx
			jmp limpiar_Buffer_Loop

		limpiar_Buffer_Exit:
			pop rcx
			ret

	limpiar_Buffer_2:
		push rcx
		xor rcx, rcx

		limpiar_Buffer_2Loop:
			cmp rcx, MAX_FILE_SZ
			je limpiar_Buffer_2Exit
			;limpiar segundo  uffer auxiliar
			mov [auxBufferLine2 + rcx], byte 0
			inc rcx
			jmp limpiar_Buffer_2Loop

		limpiar_Buffer_2Exit:
			pop rcx
			ret

	limpiar_Buffer_3:
		push rcx
		xor rcx, rcx

		limpiar_Buffer_3Loop:
			cmp rcx, MAX_FILE_SZ
			je limpiar_Buffer_3Exit
			;limpiar tercer buffer auxiliar
			mov [auxBufferLine3 + rcx], byte 0 							
			inc rcx
			jmp limpiar_Buffer_3Loop

		limpiar_Buffer_3Exit:
			pop rcx
			ret
			siguienteLinea:
		push rcx
		push rdx

		xor rdx, rdx
		mov rcx, r11
		sub rcx,2 
		sub rsi, 2

		siguienteLineaL:
			cmp rcx, rsi
			jge siguienteLineaP
			mov al, [in_file + rcx]
			;guardar lo que esta despues de la primer linea
			mov [auxBufferLine2 + rdx], al]
			inc rcx
			inc rdx
			jmp siguienteLineaL

		siguienteLineaP:
			pop rdx
			pop rcx
			ret

	siguienteLinea2:
		push rcx
		push rdx
		xor rdx, rdx
		mov rcx, r8

		siguienteLinea2L:
			cmp rcx, r12
			jge siguienteLinea2P
			mov al, [in_file + rcx]
			;guardar lo esta despues de la segunda linea
			mov [auxBufferLine3 + rdx], al  
			inc rcx
			inc rdx
			jmp siguienteLinea2L

		siguienteLinea2P:
			pop rdx
			pop rcx
			ret

	ProcesarArchivo:

	mov r9, r12
	xor r8, r8 ; posiicion de lectura de in_file
	xor rax, rax
	xor r12, r12 ; tendra todas las lineas que hay en la matriz 
	xor r10, r10 ; fila actual en al cual se encuentra al matriz 
	

	read_line:
		xor rcx, rcx 

		removerBlancos:
			cmp r8, r9
			if e
			ret
			endif
			cmp rcx, 0
			if e 
				xor rax, rax
				mov al , [in_file + r8]
				cmp al, 0 ; espacio en blanco 
				if e 
					inc r8 ; incrementara para seguir con el siguiente elemento del archivo 
					jmp removerBlancos

				else
					cmp al, 10
					if e
						mov [line + rcx], al
						inc r8
						cmp r8, r9 
						if e 
							ret
						endif
						jmp duplicados
					endif
							
						mov [line + rcx], al
						inc rcx
						inc r8	
						jmp removerBlancos
				endif
			else 
				xor rax, rax
				mov al , [in_file + r8]
				cmp al, 0 ; espacio en blanco 
				if e 
					xor rbx, rbx
					mov bl , [in_file + r8 + 1]
					cmp bl, 0 ; espacio en blanco 
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
							jmp duplicados
						endif
								
							mov [line + rcx], al
							inc rcx
							inc r8	
							jmp removerBlancos
					endif
				else 
						cmp al, 10
						if e
							mov [line + rcx], al
							inc r8
							cmp r8, r9 
							if e 
								jmp duplicados
							endif
								
							
							jmp duplicados
						endif
								
							mov [line + rcx], al
							inc rcx
							inc r8	
							jmp removerBlancos
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
			write strNum, strNumlen
			jmp read_line
		endif 
		mov byte [MATRIZ + rdi], al
		inc rcx
		inc rdi
		jmp auxAgregarMatriz 

duplicados:
	xor rcx, rcx 
	xor rax, rax
	cmp r12, 0 ; esto nos dira si hay algun elemento en la matriz 
	if e 
		jmp agregarMatriz

	else
		mov rdi, 0
		mov rbx, 0 ; contara el maximo de la matriz 
		xor r15, r15 ; contara las iteraciones
		duplicadoMatriz:
			xor rcx, rcx ; reinicia el contador xD
			mov rdi, rbx
			auxDuplicado:
				mov al, [line + rcx]
				cmp [MATRIZ + rdi], al
				if e
					cmp byte [MATRIZ + rdi ], 10 
					; esto se hara ya que si se acaba primero una cadena antes que otra
					if e
						cmp byte [line + rcx ], 10 
						; esto significa que son iguales 
						if e 

							jmp read_line
						else 

							add rbx, MatrizMax
							inc r15

							jmp duplicadoMatriz
						endif 
					else

						inc rcx
						inc rdi 
						jmp auxDuplicado
					endif 
				else
					inc r15
					cmp r15, r12
					if e 
						jmp agregarMatriz
					endif 
					add rbx, MatrizMax
					jmp duplicadoMatriz
				endif 
	endif

compararLineBuffer:
	push rcx
	push rdx
	push rax
	;comparar las lineas para saber si es mayor o CaracerMenor
	push rbx 	

	xor rcx, rcx
	xor rdx, rdx
	xor rax, rax
	xor rbx, rbx

		compararLineBufferLoop:
			xor rax, rax
			xor rbx, rbx

			mov al, [line + rcx]
			mov bl, [line2 + rdx]

			cmp r11, r12
			jge final

			cmp bl, al
			jb CaracerMenor

			cmp al, bl
			je nextLetter

			pop rbx
			pop rax
			pop rdx
			pop rcx

			jmp nextLine

		nextLetter:
			inc rcx
			inc rdx
			
			cmp r15, r14
			je verificar

			jmp compararLineBufferLoop

		verificar:
			cmp [line + rcx], byte 0
			je nextLine

			cmp [line2 + rdx], byte 0
			je nextLine

			jmp compararLineBufferLoop

		nextLine:
			mov rcx, r11
			call getline

			mov rcx, r11
			call getline2

			jmp compararLineBuffer

		CaracerMenor:
			pop rbx
			pop rax
			pop rdx
			pop rcx

			inc rdi
			call limpiar_Buffer_
			call limpiar_Buffer_2
			call limpiar_Buffer_3

			call GuardaLinea
			call siguienteLinea
			call siguienteLinea2

			call clear_in_file

			call cambioLine1
			call insertBuffer2
			call cambioLine2
			call insertBuffer1  			;swap
			call cambioLine3

			mov r11, r8
			jmp nextLine

	cambioLine1:
		push rcx
		xor rcx, rcx
		cambioLine1L:
			xor rax, rax
			mov al, [auxBufferLine + rcx]

			cmp al, 0
			if e
				jmp cambioLine1P 
			endif					;poner en el in_file lo que esta antes de la primer linea que se compara

			mov [in_file + r10], al

			inc rcx
			inc r10

			jmp cambioLine1L

		cambioLine1P:
			pop rcx
			ret

	cambioLine2:
		push rcx
		xor rcx, rcx
		cambioLine2L:
			xor rax, rax
			mov al, [auxBufferLine2 + rcx]

			cmp al, 0
			if e
				jmp cambioLine2P
			endif

			mov [in_file + r10], al 				;poner en el in_file lo esta despues de la primer linea que se compara

			inc rcx
			inc r10

			jmp cambioLine2L

		cambioLine2P:
			pop rcx
			ret

	cambioLine3:
		push rcx
		xor rcx, rcx
		cambioLine3L:
			xor rax, rax
			mov al, [auxBufferLine3 + rcx]

			cmp al, 0
			if e
				jmp cambioLine3P 
			endif 						;poner en el buffer lo que esta despues de la segunda linea que se compara 

			mov [in_file + r10], al

			inc rcx
			inc r10

			jmp cambioLine3L

		cambioLine3P:
			pop rcx
			ret

	;metodos de insertar para la matriz
	insertBuffer1:
		push rcx
		xor rcx, rcx
		insertBuffer1L:
			xor rax, rax
			mov al, [line + rcx]

			cmp al, 0
			if e
				jmp insertBuffer1P
			endif 

			;insertar la primer linea en el buffer
			mov [in_file + r10], al 									

			inc rcx
			inc r10

			jmp insertBuffer1L

		insertBuffer1P:
			mov [in_file + r10], byte 10
			inc r10
			pop rcx
			ret

	insertBuffer2:
		push rcx
		xor rcx, rcx
		insertBuffer2L:
			xor rax, rax
			mov al, [line2 + rcx]

			cmp al, 0
			if e
				jmp insertBuffer2P
			endif 	

			;insertar la segunda linea en el buffer
			mov [in_file + r10], al 									

			inc rcx
			inc r10

			jmp insertBuffer2L

		insertBuffer2P:
			mov [in_file + r10], byte 10
			inc r10
			pop rcx
			ret

	GuardaLinea:
		push rcx
		push rdx

		xor rcx, rcx

		xor rdx, rdx

		GuardaLineaLoop:
			cmp rcx, r9
			je GuardaLineaP

			xor rax, rax

			;guardar lo que esta antes de la primer linea
			mov al, [in_file + rcx] 							
			mov [auxBufferLine + rdx], al

			inc rcx
			inc rdx

			jmp GuardaLineaLoop
		GuardaLineaP:
			pop rdx
			pop rcx
			ret