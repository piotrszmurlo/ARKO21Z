; pixel_array - rdi
; width - rsi
; height - rdx
; scaled_pixel_array_buffer - rcx
; scaled_bmp_width - r8
; scaled_bmp_height - r9

; widthBytes - [rbp-4]
; newWidthBytes - [rbp-8]

section	.text
global bilinear_interpolation

bilinear_interpolation:

    ; create stack frame

    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; callee-save registers
    push rbx       
    push r12
    push r13
    push r14
    push r15

    cvtsi2ss xmm0, esi  ; xmm0 = (float) width
    cvtsi2ss xmm1, r8d  ; xmm1 = (float) scaled_width
    divss xmm0, xmm1    ; xmm0 = x_scale

    cvtsi2ss xmm1, edx  ; xmm1 = (float) height
    cvtsi2ss xmm2, r9d  ; xmm2 = (float) scaled_height
    divss xmm1, xmm2    ; xmm1 = y_scale

    lea r10d, [esi+esi*2] ; r10d = width*3
    mov eax, esi        
    and eax, 3          ; eax = width%4 (padding)
    add r10d, eax       ; r10 = byte_width + padding
    mov [rbp-4], r10d   ; [rbp-4] = byte_width + padding (dword)

    mov eax, r8d        ; eax = scaled_width
    and eax, 3          ; eax = scaled_width%4 (padding)
    lea r11d, [r8d+r8d*2]
    add r11d, eax       ; r11 = scaled_byte_width + padding
    mov [rbp-8], r10d   ; [rbp-8] = scaled_byte_width + padding (dword)

    dec rsi
    dec rdx
    xor r12, r12        ; scaled_x = 0
    xor r13, r13        ; scaled_y = 0
; xmm0 = x_scale, xmm1 = y_scale
; r12 = scaled_x, r13 = scaled_y, rsi - w, rdi - h

loop_over_scaled_pixel_array:
    cvtsi2ss xmm2, r12  ; xmm2 = (float) scaled_x
    cvtsi2ss xmm3, r13  ; xmm3 = (float) scaled_y
    mulss xmm2, xmm0    ; xmm2 = scaled_x * x_scale
    mulss xmm3, xmm1    ; xmm3 = scaled_y * y_scale
    cvttss2si r14d, xmm2 ; r14 = (int) scaled_x * x_scale
    cvttss2si r15d, xmm3 ; r15 = (int) scaled_y * y_scale
    ; r14 - x, r15 - y
    cmp r14d, esi       ; if (x < width) jump x
    jb x                ; else:
    cvtsi2ss xmm2, esi  ; xmm2 = (float) width
    mov r14d, esi       ; r14 = width 
x:
    cmp r15d, edx       ; if (y < height) jump y
    jb y                ; else:
    cvtsi2ss xmm3, edx  ; xmm3 = (float) height
    mov r15d, edx       ; rdx = height
y:
    cvtsi2ss xmm4, r14d  ; xmm4 = (float) x
    cvtsi2ss xmm5, r15d  ; xmm5 = (float) y

    subss xmm2, xmm4     ; xmm2 = x_diff
    subss xmm3, xmm5     ; xmm3 = y_diff

    mov eax, r15d
    mul DWORD [rbp-4]   ; eax = y*byte_width

    lea ebx, [r14d+r14d*2]    ;ebx = x*3
    add ebx, eax        ; ebx = x*3 + y*byte_width
    add rbx, rdi        ; 0,0 pixel address (A)

    mov eax, [rbp-4]    ; eax = byte_width
    mov r11, rbx        ; r11 = 0,0 pixel address
    add r11, rax        ; 0,1 pixel address (C)

    mov eax, r13d       ; eax = scaled_y
    mul DWORD [rbp-8]   ; eax = scaled_y*scaled_byte_width
    lea r10d, [r12d+r12d*2] ; scaled_x*3!!!!r10d=r15d(r13)!!!!!!!

    add r10d, eax           ; scaled_x*3 + scaled_y*scaled_byte_width
    add r10, rcx            ; new pixel address

    xor r14, r14            ; color_offset = 0
; r14 = color_offset, rbx - A, r11 - C, r10 - new_pix, r12 - scaled_x, r13 - scaled_y
; rsi - w, rdi - h
loop_color:
    movzx edx, BYTE [rbx+r14]  ; edx = color (0,0)
    cvtsi2ss xmm4, edx         ; xmm4 = (float) color (0,0)
    movzx edx, BYTE [rbx+r14+3]; edx = color (1,0)
    cvtsi2ss xmm5, edx         ; xmm5 = (float) color (1,0)
    movzx edx, BYTE [r11+r14]  ; edx = color (0,1)
    cvtsi2ss xmm6, edx         ; xmm6 = (float) color (0,1)
    movzx edx, BYTE [r11+r14+3]; edx = color (1,1)
    cvtsi2ss xmm7, edx         ; xmm7 = (float) color (1,1)

    ;interpolation
    subss xmm5, xmm4
    mulss xmm5, xmm2
    addss xmm5, xmm4            ; xmm5 = color (scaled_x, 0)
    subss xmm7, xmm6
    mulss xmm7, xmm2
    addss xmm7, xmm6            ; xmm7 = color (scaled_x, 1)
    subss xmm7, xmm5
    mulss xmm7, xmm3
    addss xmm7, xmm5            ; xmm7 = color (scaled_x, scaled_y)

    cvtss2si edx, xmm7          ; (int) color (scaled_x, scaled_y)
    mov [r10+r14], dl           ; move color byte to new_pixel_address+color_offset
    inc r14
    cmp r14, 3
    jnz loop_color              ; if color_offset < 3 loop_color
    inc r12                     ; scaled_x++
    cmp r12, r8                 ; if scaled_x < scaled_width loop
    jnz loop_over_scaled_pixel_array
    xor r12, r12                ; x = 0
    inc r13                     ; scaled_y++
    cmp r13, r9                 ; if y < scaled_y loop
    jnz loop_over_scaled_pixel_array

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    mov rsp, rbp
    pop rbp
    ret