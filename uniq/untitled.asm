aux_read_line:
				xor rax, rax
				mov al , [in_file + r8]
				cmp al, 10
				if e
				
					mov [line + rcx], al
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
					jmp aux_read_line
				