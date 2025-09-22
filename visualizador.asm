;-----------------------------------------------------------------
; Proyecto: Lectura de config.ini y oedenamiento del inventario 
;-----------------------------------------------------------------
section .data
    config_filename   db "config.ini",0       ; Nombre del archivo de configuración
    inventario_filename db "inventario.txt",0 ;Nombre del archivo de inventario
    barra_default     db "█",0                ; Valor por defecto del carácter barra
    salto_linea      db 10,0                 ; '\n' para buscar fin de línea
    dos_puntos       db ':',0
    msg1 db "Parseando inventario...",10
    msg1_len equ $-msg1
    msg2 db "Fin de parseo!",10
    msg2_len equ $-msg2
    msg_sortin db "Entrando a ordenamiento...",10
    msg_sortin_len equ $-msg_sortin
    msg_sortout db "Saliendo de ordenamiento...",10
    msg_sortout_len equ $-msg_sortout


section .bss
    config_buffer     resb 256                ; Buffer para leer el archivo completo
    inventario_buffer resb 256		      ; Buffer para leer el archivo completo
    linea_buffer      resb 64                 ; Buffer intermedio por línea
    nombre_producto   resb 32*10              ; Hasta 10 productos, 32 bytes para cada uno
    valor_producto    resd 10                 ; Hasta 10 productos, cambio resd 10= 4 bytes cu
    
    ;Buffers para confi
    
    caracter_barra       resb 4               ; Para guardar caracter de config.ini
    color_barra          resb 4               ; Para guardar color
    color_fondo          resb 4               ; Para guardar color de fondo
    inventario_len       resq 1		      ; para para guardar longuitud de dartos leidos 
    temp_nombre          resb 32
    temp_valor           resd 1               ; contener el valor swap
    
    buffer_decimal       resb 12              ; buffer impresion decimal
    
   

section .text
    global _start
   mov rax, 1
   mov rdi, 1
   mov rsi, msg1
   mov rdx, msg1_len
   syscall


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
    mov rdi, 0                    ; índice de producto (0..9)
    parse_loop:
        cmp rdi, 10                 ; ¿Ya tenemos 10 productos?
        jge fin_parseo
        mov rax, 0
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
    	mov byte [rdx+rcx], 0
    	inc rsi
    	; Leer valor (ahora permite varios dígitos)
    	mov rax, 0
    read_value_loop:
    	mov bl, [rsi]
    	cmp bl, 10            ; ¿fin de línea?
    	je store_value
    	cmp bl, 0
   	je store_value
    	sub bl, '0'
    	imul rax, rax, 10
    	movzx rcx, bl
    	add rax, rcx         ; rax = rax*10 + dígito
    	inc rsi
    	jmp read_value_loop
    store_value:
    	mov rdx, valor_producto
    	mov rcx, rdi
    	shl rcx, 2            ; 4 bytes por entero
    	add rdx, rcx
    	mov [rdx], eax        ; guarda valor (32 bits)
    	cmp byte [rsi], 0
    	je fin_parseo
    	inc rsi               ; salto línea
    	inc rdi
    	jmp parse_loop

    fin_parseo:
    	mov rbx, rdi          ; cantidad de productos leidos
    mov rax, 1
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall

    
    ;======= ORDENAR ALFABÉTICAMENTE ==========
    call ordenar_alfabetico
    
    mov eax, ebx
    mov rdi, buffer_decimal
    call dec_print
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_decimal
    mov rdx, r12
    syscall

    ;======= IMPRIMIR ORDENADO ================
    call imprimir_ordenado

    ; Finaliza el programa
    mov rax, 60
    mov rdi, 0
    syscall

;----------------------------------------------
; Bubble Sort de los productos
;----------------------------------------------
ordenar_alfabetico:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_sortin   ; "Entrando..."
    mov rdx, msg_sortin_len
    syscall

    cmp rbx, 1
    jle end_sorting
    mov r10, rbx   ; r10 = total productos

    xor r8, r8             ; i = 0
outer_loop:
    cmp r8, r10
    jge next_outer_all

    mov r9, 0              ; j = 0
    mov r11, r10
    sub r11, r8 
    dec r11                ; r11 = n-i-1

inner_loop:
    cmp r9, r11
    jge next_outer         
    mov r12, nombre_producto

    mov r13, r9
    imul r13, r13, 32
    add r12, r13          ; nombre producto r9

    mov r14, r12
    add r14, 32          ; nombre producto r9+1

    mov rdi, r12
    mov rsi, r14
    mov rcx, 32
compare_names:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jb no_swap
    ja do_swap
    cmp al, 0
    je no_swap
    inc rdi
    inc rsi
    loop compare_names

no_swap:
    inc r9
    jmp inner_loop

do_swap:
    mov r13,r9   ; validar r9+1<r10
    inc r13
    cmp r13,r10
    jge .skip_swap     ;si j+1 >= num_productos saltar swap

    push rcx
    mov rcx, 32
    mov rdi, temp_nombre
    mov rsi, r12
    rep movsb
    mov rcx, 32
    mov rdi, r12
    mov rsi, r14
    rep movsb
    mov rcx, 32
    mov rdi, r14
    mov rsi, temp_nombre
    rep movsb
    pop rcx
    ; swap valores (4 bytes)
    mov r15, valor_producto
    mov r13, r9
    shl r13, 2
    add r15, r13       ; valor_producto[j]
    mov eax, [r15]     ; valor[j]
    mov rdx, r15
    add rdx, 4         ; valor_producto[j+1]
    mov ecx, [rdx]     ; valor[j+1]
    mov [r15], ecx
    mov [rdx], eax

.skip_swap:
    inc r9
    jmp inner_loop

next_outer:
    inc r8
    jmp outer_loop

next_outer_all:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_sortout  ; "Saliendo..."
    mov rdx, msg_sortout_len
    syscall
end_sorting:
    ret


;----------------------------------------------
; Imprime nombres y valores ordenados
;----------------------------------------------
imprimir_ordenado:
    xor r9, r9            ; índice del producto
.print_loop:
    cmp r9, rbx
    jge .fin
    ; Imprime nombre
    mov rdx, nombre_producto
    mov rax, r9
    imul rax, rax, 32
    add rdx, rax
    xor rcx, rcx
.send_char:
    mov al, [rdx+rcx]
    cmp al, 0
    je .impr_colon
    mov rax, 1
    mov rdi, 1
    lea rsi, [rdx+rcx]
    mov rdx, 1
    syscall
    inc rcx
    jmp .send_char
.impr_colon:
    mov rax, 1
    mov rdi, 1
    mov rsi, dos_puntos
    mov rdx, 1
    syscall
    ; Imprime decimal (buffer_decimal) el valor
    mov rcx, valor_producto
    mov rax, r9           ; índice de producto
    shl rax, 2
    add rcx, rax
    mov eax, [rcx]         ; valor a imprimir (32 bits, unsigned)
    mov rdi, buffer_decimal
    call dec_print
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_decimal
    mov rdx, r12           ; r12 contiene cantidad de dígitos calculados
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, salto_linea
    mov rdx, 1
    syscall
    inc r9
    jmp .print_loop
.fin:
    ret

;----------------------------------------------
; Convierte eax a decimal-ASCII, lo deja en rdi, 
; retorna en r12 la cantidad de dígitos usados.
; buffer debe tener al menos 12 bytes.
dec_print:
    mov rcx, 10
    mov rbx, rdi
    add rbx, 11
    mov byte [rbx], 0    ; null (no necesario para write, sí para debug)
    mov r12, 0
    mov rdx, 0
    cmp eax, 0
    jne .loop
    mov byte [rbx-1], '0'
    mov r12, 1
    mov rdi, rbx
    dec rdi
    ret
.loop:
    mov edx, 0
    div ecx              ; eax/10, residuo en edx
    add dl, '0'
    dec rbx
    mov [rbx], dl
    inc r12
    test eax, eax
    jnz .loop
    mov rdi, rbx
    ret
