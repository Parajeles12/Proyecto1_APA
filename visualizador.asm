;-----------------------------------------------------------------
; Proyecto: Lectura de config.ini
;-----------------------------------------------------------------
section .data
    config_filename   db "config.ini",0       ; Nombre del archivo de configuración
    inventario_filename db "inventario.txt",0 ;Nombre del archivo de inventario
    barra_default     db "█",0                ; Valor por defecto del carácter barra
    salto_linea      db 10,0                 ; '\n' para buscar fin de línea
    dos_puntos       db ':',0

section .bss
    config_buffer     resb 256                ; Buffer para leer el archivo completo
    inventario_buffer resb 256		      ; Buffer para leer el archivo completo
    linea_buffer      resb 64                 ; Buffer intermedio por línea
    nombre_producto   resb 32*10              ; Hasta 10 productos, 32 bytes para cada uno
    valor_producto    resb 10                 ; Hasta 10 productos
    
    ;Buffers para confi
    
    caracter_barra    resb 4                  ; Para guardar caracter de config.ini
    color_barra      resb 4                   ; Para guardar color
    color_fondo      resb 4                   ; Para guardar color de fondo
    inventario_len       resq 1		      ; para para guardar longuitud de dartos leidos 
   

section .text
    global _start
    mov [inventario_len], rcx
    

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
    
    
    ; ================ Leyendo inventario.txt ==============
    mov rax, 2                      ; syscall: open
    mov rdi, inventario_filename    ; archivo inventario.txt
    mov rsi, 0                      ; O_RDONLY
    mov rdx, 0
    syscall
    mov rbx, rax                    ; file descriptor
    mov rax, 0                      ; syscall: read
    mov rdi, rbx
    mov rsi, inventario_buffer
    mov rdx, 256
    syscall
    mov rcx, rax                    ; longitud de lectura

    mov rax, 3                      ; syscall: close
    mov rdi, rbx
    syscall

    ; ================ Parseando inventario_buffer =========
    ; Aquí se parsea inventario_buffer línea por línea
    ; Cada línea: nombre:valor\n
    mov rsi, inventario_buffer
    xor rdi, rdi                    ; índice de producto (0..9)
    parse_loop:
        cmp rdi, 10                 ; ¿Ya tenemos 10 productos?
        jge fin_parseo
        ; Copiar nombre hasta ':'
        mov rdx, nombre_producto    ; destino: nombre_producto[32*<indice>]
        imul rax, rdi, 32           ; offset producto actual
        add rdx, rax
        xor rcx, rcx                ; contador de caracteres de nombre
    copy_name:
        mov al, [rsi]
        cmp al, ':'                 ; Fin de nombre
        je end_name
        cmp al,0                   ; Verificación fin de buffer
        je fin_parseo
        mov [rdx+rcx], al
        inc rcx
        inc rsi
        jmp copy_name
    end_name:
        mov byte [rdx+rcx], 0       ; Null-terminator para nombre
        inc rsi                     ; Saltar ':'
        ; Leer valor (decimal simple)
        mov al, [rsi]
        sub al, '0'                 ; Asume 1 dígito (valores <= 9)
        mov rdx, valor_producto
        add rdx, rdi
        mov [rdx], al
        inc rsi
        ; Saltar hasta fin de línea
    skip_line:
        mov al, [rsi]
        cmp al, 10                  ; Salto de línea
        je next_producto
        cmp al, 0                   ; Fin de buffer
        je fin_parseo
        inc rsi
        jmp skip_line
    next_producto:
        inc rsi
        inc rdi
        jmp parse_loop

    fin_parseo:

    call _imprime_inventario
    
    ; Finaliza el programa
    
    mov rax, 60                 ; syscall: exit
    mov rdi, 0                  ; código de salida
    syscall

_imprime_inventario:
    mov rsi, inventario_buffer         ; Inicio del buffer
    mov rcx, [inventario_len]          ; Cantidad de bytes a imprimir (guardada antes)
.print_loop:
    cmp rcx, 0
    je .fin
    mov rax, 1         ; syscall: write
    mov rdi, 1         ; file descriptor: stdout
    mov rdx, 1         ; cantidad: 1 byte
    syscall
    inc rsi
    dec rcx
    jmp .print_loop
.fin:
    ret
