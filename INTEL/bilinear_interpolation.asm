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
    sub rsp, 40

    ; callee-save registers
    push rbx       
    push r12
    push r13
    push r14
    push r15

    cvtsi2ss xmm0, esi  ; xmm0 = (float) width
    cvtsi2ss xmm1, r8d  ; xmm1 = (float) scaled_width
    divss xmm0, xmm1    ; xmm0 = width/scaled_width

    cvtsi2ss xmm1, edx  ; xmm1 = (float) height
    cvtsi2ss xmm2, r9d  ; xmm2 = (float) scaled_height
    divss xmm1, xmm2    ; xm1 = height/scaled_height

    lea r10d, [esi + esi*2]         ; r10d = width*3
    mov eax, esi        
    and eax, 3          ; eax = width%4 (padding)
    add r10d, eax       ; r10d = byte_width + padding

    mov eax, r8d        ; eax = scaled_width
    and eax, 3          ; eax = scaled_width%4 (padding)
    lea r11d, [r8d, r8d*2]
    add r11d, eax       ; r11d = scaled_byte_width + padding
    





    