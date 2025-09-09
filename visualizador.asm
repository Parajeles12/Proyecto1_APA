;-----------------------------------------------------------------
; Proyecto: Lectura de config.ini
;-----------------------------------------------------------------
section .data
    config_filename   db "config.ini",0       ; Nombre del archivo de configuración
    barra_default     db "█",0                ; Valor por defecto del carácter barra
    salto_linea      db 10,0                 ; '\n' para buscar fin de línea

section .bss
    config_buffer     resb 256                ; Buffer para leer el archivo completo
    linea_buffer      resb 64                 ; Buffer intermedio por línea
    caracter_barra    resb 4                  ; Para guardar caracter de config.ini
    color_barra      resb 4                   ; Para guardar color
    color_fondo      resb 4                   ; Para guardar color de fondo
    config_len       resq 1		      ; para para guardar longuitud de dartos leidos 
   

section .text
    global _start
    global _print_config

_start:
    ; Abrir el archivo de configuración (config.ini)
    mov rax, 2                  ; syscall: open
    mov rdi, config_filename    ; nombre del archivo
    mov rsi, 0                  ; O_RDONLY
    mov rdx, 0                  ; flags (sin permisos especiales)
    syscall
    mov rbx, rax                ; Guardar el file descriptor en rbx

    ; Leer el contenido del archivo en config_buffer
    mov rax, 0                  ; syscall: read
    mov rdi, rbx                ; file descriptor de config.ini
    mov rsi, config_buffer      ; dirección del buffer
    mov rdx, 256                ; cantidad máxima a leer
    syscall

    ; TODO: Parsear el buffer, extraer los valores buscados              <---- Aquí va la lógica de parsing

    ; Cerrar el archivo
    mov rax, 3                  ; syscall: close
    mov rdi, rbx                ; file descriptor
    syscall
    
    call _print_config

    ; Finaliza el programa
    
    mov rax, 60                 ; syscall: exit
    mov rdi, 0                  ; código de salida
    syscall
;-------------------- Segmento de código para mostrar configuración --------------------

_print_config:
    mov rsi, config_buffer      ; Apunta al inicio del buffer
    mov rcx, config_len         ; Longitud del contenido leído

.loop_print:
    cmp rcx, 0                 ; ¿Se terminó el buffer?
    je .fin_print              ; Sí: termina rutina

    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rdx, 1                 ; Imprime un byte a la vez
    syscall

    inc rsi                    ; Siguiente caracter
    dec rcx
    jmp .loop_print

.fin_print:

    ret
