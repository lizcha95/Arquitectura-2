section .data
	errorNoArg		db "ERROR - Falta de argumentos", 10
	errNoArgLen		equ $-errorNoArg

	errorInvArg		db "ERROR - No es un argumento valido", 10
	errInvArgLen	equ $-errorInvArg

section .bss
	buffLen equ 2048
	buffer: resb buffLen

	fileNameLen equ 64
	fileName: resb fileNameLen

	delimitLen equ 128
	delimitador: resb delimitLen

	formatLen equ 2048
	format: resb formatLen

	outputLen: equ 2048
	output: resb outputLen

	endFlag: resb 1

	escape: equ 92
	argv: equ 37
	quot: equ 34
	endl: equ 10
	null: equ 0

section .text

GLOBAL _start

%macro PRINT 2
	push rcx
	push rax
	push rdi
	push rsi
	push rdx

	mov rax, 1
	mov rdi, 1
	mov rsi, %1
	mov rdx, %2
	syscall

	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop rcx
%endmacro

_start:
		nop
	main:
		call read
		call analyzeFile
		jmp exit

	exit:
		mov rax, 60
		mov rdi, 0
		syscall

	;////////////////////////////////////////////////////////////////////////////
	;/// READ
	;////////////////////////////////////////////////////////////////////////////
	;///
	;/// Registros
	;///
	;/// Entrada:
	;/// -
	;///
	;/// Utilizados:
	;/// r8  : Puntero a las direccion en memoria del parametro
	;/// r9	 : Contiene el string del parametro a recorrer 
	;/// r10 : Contador/Iterador para recorrer el string del nombre del archivo
	;/// rcx : Contador/Iterador para recorrer los parametros del programa
	;/// rax : Guarda el caracter por analizar
	;/// rdx : Contador/Iterador para recorrer el string del parametro
	;/// rsi : Contador/Iterador para recorrer el string del formato del archivo
	;///
	;/// rax, rdx, rdi, rsi : son tambien utilizados para syscall
	;///
	;/// Salida:
	;/// -
	;///
	;////////////////////////////////////////////////////////////////////////////
	;///
	;/// 1. Conseguir el numero de parametros
	;///    a. Comparar la cantidad de parametros
	;/// 	b. Puntero al segundo parametro del archivo
	;///		(El primero es el nombre del programa)
	;///    c. Recorrer los demas parametros
	;///		i.	 Puntero al string del primer parametro
	;///		ii.  Revisar el primer caracter
	;///			 >	'-' para el delimitador y el formato
	;///			 	-	Revisar el segundo caracter
	;///					'f' - formato
	;///					'd' - delimitador
	;///				-	Mover los caracteres al buffer determinado
	;///				-	Agregar un caracter nulo (0x00) al final del formato
	;///			 >	el resto verifica el nombre del archivo
	;///				-	Mover los caracteres al buffer del archivo
	;///		iii. Mover al siguiente parametro hasta llegar al ultimo
	;/// 2. Leer el archivo
	;///    a. Abrir el archivo (RAX queda el fd)
	;///    b. Guardar contenido a un buffer
	;///    c. Cerrar el archivo
	;///
	;///////////////////////////////////////////////////////////////////////////

	read:
		;8
		push r8 ;16
		push r9 ;24
		push r10 ;32
		push rcx ;40
		push rax ;48
		push rdi ;56
		push rdx ;64
		push rsi ;72


		xor r10, r10

		mov	r8, rsp
		add r8, 72			;Mover 8n bytes
		mov	rcx, [r8]		;numero de param rcx
		cmp	rcx, 4
		jb noArguments

		add r8, 8
		dec rcx
		read.param:
			cmp	rcx,  null		;ultimo parametro
			je	read.openFile
			add	r8,	8			;incrementar puntero
			dec	rcx				;reducir el numero de parametros
			jmp	read.check

		read.check:
			mov	r9,	[r8]
			xor rdx, rdx
			read.checkStart:
				mov al, [r9+rdx]
				cmp	al, 45			;'-'	
				je  read.checkParam
				jmp read.checkFileName
			
		read.checkParam:
			inc rdx
			mov al, [r9+rdx]
			cmp al, 100				;'d'
			je read.checkDelim
			cmp al, 102				;'f'
			je read.checkFormat
			jmp invArguments

		read.checkFileName:
			mov al, [r9+rdx]
			cmp	al, null	
			je  read.param
			mov [fileName+r10], al
			inc rdx
			inc r10
			jmp read.checkFileName

		read.checkDelim:
			inc rdx
			mov al, [r9+rdx]
			cmp al, null
			je invArguments
			xor rsi, rsi
			checkDelim.loop:
				mov [delimitador+rsi], al
				inc rdx
				mov al, [r9+rdx]
				cmp al, null
				je checkDelim.end
				inc rsi
				jmp checkDelim.loop
			checkDelim.end:
				inc rsi
				mov [delimitador+rsi], al
				jmp read.param

		read.checkFormat:
			xor rsi, rsi
			checkFormat.loop:
				inc rdx
				mov al, [r9+rdx]
				cmp al, null
				je checkFormat.end
				mov [format+rsi], al
				inc rsi
				jmp checkFormat.loop
			checkFormat.end:
				mov byte [format+rsi], null		;delimita el final del formato con un 0x00
				je read.param


		noArguments:
			PRINT errorNoArg, errNoArgLen
			pop rsi
			pop rdx
			pop rdi
			pop rax
			pop rcx
			pop r10
			pop r9
			pop r8
			jmp exit

		invArguments:
			PRINT errorInvArg, errInvArgLen
			pop rsi
			pop rdx
			pop rdi
			pop rax
			pop rcx
			pop r10
			pop r9
			pop r8
			jmp exit

		read.openFile:
			mov byte [fileName+r10], 0	;null terminated filename

			mov rax, 2
			mov rdi, fileName
			mov rsi, 0				;read only
			mov rdx, 0644
			syscall

			file_read:
				mov rdi, rax
				mov rax, 0		
				mov rsi, buffer
				mov rdx, buffLen
				syscall


			close_file:
				mov rax, 3
				mov rdi, rax
				syscall

		pop rsi
		pop rdx
		pop rdi
		pop rax
		pop rcx
		pop r10
		pop r9
		pop r8
		ret

	;////////////////////////////////////////////////////////////////////////////
	;/// ANALYZE FILE
	;////////////////////////////////////////////////////////////////////////////
	;///
	;/// Registros
	;///
	;/// Entrada:
	;/// -
	;///
	;/// Utilizados:
	;/// r8  : Posicion de los elementos dentro del archivo
	;/// r9	 : Contador/Iterador para recorrer el buffer del output
	;/// r10 : Contador de la cantidad posiciones 'pushed'
	;/// r11 : Guarda el numero en formato 'int'
	;/// r12 : Puntero para recorrer la pila
	;/// r13 : backup del r10
	;/// rcx : Contador/Iterador para recorrer el buffer del archivo
	;/// rax : Guarda el caracter por analizar
	;/// rdx : Contador/Iterador para recorrer el buffer del formato
	;///
	;/// Salida:
	;/// -
	;///
	;////////////////////////////////////////////////////////////////////////////
	;///
	;/// 1. Recorrer el buffer del archivo hasta el final, linea por linea
	;///    a. Mover caracter del buffer del archivo al RAX
	;/// 	b. Comparar ese caracter
	;///		i.	 (0x00) - nulo
	;///			 >	Prender la bandera de finalizar
	;///			 >	Revisar la linea anterior
	;///		ii.  delimitador
	;///			 >	Agregar posicion al stack
	;///		iii. (0x0a) - cambio de linea
	;///			 > Revisar la linea anterior
	;///		iv.	 Siguiente caracter
	;///    c. Revisar la linea anterior
	;///		i.	 Agregar ultima posicion al stack
	;///		ii.  Mover caracter del buffer del formato al RAX
	;///		iii. Comparar ese caracter
	;///			 >	(0x00) - nulo
	;///			 	-	Imprimir el buffer de output
	;///				-	Comparar el siguiente caracter del buffer del archivo
	;///			 >	(0x25) - %
	;///				-	Verificar el caracter siguiente
	;///				-	nulo	->	imprimir
	;///				-	%		->	verificar el caracter siguiente
	;///				-	49 <= x <= 57 (numero) -> 'buscar en el stack la
	;///											   posicion del elemento'
	;///				-	el resto ->  Mover
	;///			 >	(0x5C) - \
	;///				-	Comparar el siguiente caracter si es nulo
	;///				-	Si no, agregar al buffer de output
	;///				-	Comparar el siguiente caracter
	;///			 >	Los demas
	;///				-	Agregar al buffer de output
	;///				-	Comparar el siguiente caracter
	;///		iii. Mover al siguiente parametro hasta llegar al ultimo
	;///
	;///////////////////////////////////////////////////////////////////////////

	analyzeFile:
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

		xor rcx, rcx
		xor r8, r8

		analyzeFile.nextLine:
			xor r10, r10
		analyzeFile.loop:
			mov al, [buffer+rcx]
			cmp al, null
			je analyzeFile.endLine

			xor rbx, rbx
			push rcx
			push rax
			loop.checkDelim:
				cmp byte [delimitador+rbx], 0
				je analyzeFile.addToStack
				mov al, [buffer+rcx]
				cmp al, [delimitador+rbx]
				jne loop.next
				inc rbx
				inc rcx
				jmp loop.checkDelim
			loop.next:
			pop rax
			pop rcx
			add rcx, rbx

			cmp al, endl					;nueva linea
			je analyzeFile.newLine
			inc rcx
			jmp analyzeFile.loop

		analyzeFile.addToStack:
			pop rax
			pop rcx
			add rcx, rbx
			push r8
			inc r10
			;inc rcx
			mov r8, rcx
			jmp analyzeFile.loop

		analyzeFile.endLine:
			mov byte [endFlag], 1
			jmp analyzeFile.newLine

		analyzeFile.newLine:
			push r8
			inc r10
			mov r13, r10

			xor rdx, rdx
			xor r9, r9
			output.edit:
				mov al, [format+rdx]
				cmp al, null
				je output.print
				cmp al, argv
				je output.searchVar
				cmp al, escape
				je output.escapeVar
				mov [output+r9], al
				inc rdx
				inc r9
				jmp output.edit

			output.escapeVar:
				inc rdx
				mov al, [format+rdx]
				cmp al, null
				je output.print
				mov [output+r9], al
				inc rdx
				inc r9
				jmp output.edit

			output.anotherVar:
				mov [output+r9], al
			output.searchVar:
				xor r11, r11
				inc rdx
				mov al, [format+rdx]
				cmp al, null
				je output.incompleteVar
				cmp al, argv
				je output.anotherVar
				cmp al, 49
				jb output.incorrectVar
				cmp al, 57
				ja output.incorrectVar

				searchVar.isNum:
					sub al, 48
					add r11, rax
					inc rdx
					cmp byte [format+rdx], 49
					jb searchVar.proceed
					cmp byte [format+rdx], 57
					ja searchVar.proceed

					shr r11, 3
					add r11, rax
					add r11, rax

					mov al, [format+rdx]
					jmp searchVar.isNum

				searchVar.proceed:
					mov r10, r13
					cmp r11, r10			;esta en la pila?
					ja output.edit

					mov r12, rsp

					setStack:
						cmp r10, null
						je searchVar.preLoop
						add r12, 8
						dec r10
						jmp setStack

				searchVar.preLoop:
					;inc r10
				searchVar.loop:
					cmp r10, r11
					je searchVar.BufferToOutput
					sub r12, 8
					inc r10
					jmp searchVar.loop

				searchVar.BufferToOutput:
					mov r12, [r12]
					BufferToOutput.loop:
						mov al, [buffer+r12]
						cmp al, null
						je output.edit
						cmp al, endl
						je output.edit

						xor rbx, rbx
						push r12
						push rax
						B.loop.checkDelim:
							cmp byte [delimitador+rbx], 0
							je BufferToOutput.loopEdit
							mov al, [buffer+r12]
							cmp al, [delimitador+rbx]
							jne B.loop.next
							inc rbx
							inc r12
							jmp B.loop.checkDelim
						B.loop.next:
						pop rax
						pop r12
						;add r12, rbx

						mov [output+r9], al
						inc r9
						inc r12
						jmp BufferToOutput.loop

					BufferToOutput.loopEdit:
						pop rax
						pop r12
						je output.edit


			output.incorrectVar:
				;mov byte [output+r9], argv
				;inc r9
				mov [output+r9], al
				inc rdx
				inc r9
				jmp output.edit

			output.incompleteVar:
				;mov byte [output+r9], argv
				;inc r9
				mov [output+r9], al
				jmp output.print

			output.print:
				mov byte [output+r9], endl
				inc r9
				PRINT output, r9

			clearStack:
				cmp r13, 0
				je checkEnd
				pop r8
				dec r13
				jmp clearStack

			checkEnd:
				cmp byte [endFlag], 1
				je analyzeFile.end

			inc rcx
			mov r8, rcx
			jmp analyzeFile.nextLine

		analyzeFile.end:
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