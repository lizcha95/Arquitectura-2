#********************************************************
#* Instituto Tecnológico de Costa Rica                	*
#* Escuela de Computación                               *
#* Arquitectura de Computadores                         *
#* Archivo: Makefile			           				*
#* Profesor: Erick Hernandez                            *
#* Estudiantes: Liza Chaves 2013016573                  *
#* 				Marisol González 2014160604				*
#* 				Izcar Muñoz 2015069773					*
#********************************************************

cut: cut.asm
	@nasm -f elf64 -o cut.o cut.asm
	@ld -o cut cut.o
