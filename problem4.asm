
; ==================================================
; PROBLEM 4: ATM WITHDRAWAL VALIDATION
; NASM 32-bit Assembly - Linux
; Classroom Simulation Only
; ==================================================

section .data
    namePrompt db "Enter account name: ", 0
    pinPrompt  db "Enter PIN: ", 0
    amtPrompt  db "Enter withdrawal amount: ", 0

    grantedMsg db "ACCESS GRANTED", 10, 0
    deniedMsg  db "ACCESS DENIED", 10, 0

    balanceMsg db "Current Balance: PHP ", 0
    successMsg db "WITHDRAWAL SUCCESSFUL", 10, 0
    withdrawnMsg db "Amount Withdrawn: PHP ", 0
    remainingMsg db "Remaining Balance: PHP ", 0

    invalidMsg db "INVALID AMOUNT", 10, 0
    fundsMsg   db "INSUFFICIENT FUNDS", 10, 0
    multipleMsg db "AMOUNT MUST BE A MULTIPLE OF 100", 10, 0
    nameError  db "INVALID ACCOUNT NAME", 10, 0

    newline db 10, 0
    balance dd 10000

section .bss
    nameBuffer   resb 128
    pinBuffer    resb 32
    amountBuffer resb 32

    inputChar    resb 1
    overflowFlag resb 1

    amountValue  resd 1
    numberBuffer resb 16

section .text
    global _start

; ==================================================
; MAIN PROGRAM
; ==================================================

_start:

    ; Ask for account name
    mov ecx, namePrompt
    call print_string

    mov edi, nameBuffer
    mov ebp, 127
    call read_line

    cmp eax, 0
    jle invalid_name

    ; Ask for PIN
    mov ecx, pinPrompt
    call print_string

    mov edi, pinBuffer
    mov ebp, 31
    call read_line

    ; PIN must be exactly 4 characters
    cmp eax, 4
    jne access_denied

    ; Compare each PIN character
    cmp byte [pinBuffer], '1'
    jne access_denied

    cmp byte [pinBuffer + 1], '2'
    jne access_denied

    cmp byte [pinBuffer + 2], '3'
    jne access_denied

    cmp byte [pinBuffer + 3], '4'
    jne access_denied

    ; PIN is correct
    mov ecx, grantedMsg
    call print_string

    ; Display current balance
    mov ecx, balanceMsg
    call print_string

    mov eax, [balance]
    call print_number

    mov ecx, newline
    call print_string

    ; Ask for withdrawal amount
    mov ecx, amtPrompt
    call print_string

    mov edi, amountBuffer
    mov ebp, 31
    call read_line

    cmp eax, -1
    je invalid_amount

    ; Convert ASCII amount to integer
    mov esi, amountBuffer
    call ascii_to_int

    jc invalid_amount

    ; First check: amount must be positive
    cmp eax, 0
    je invalid_amount

    mov [amountValue], eax

    ; Second check: sufficient balance
    cmp eax, [balance]
    ja insufficient_funds

    ; Third check: multiple of 100
    xor edx, edx
    mov ebx, 100
    div ebx

    cmp edx, 0
    jne invalid_multiple

    ; Deduct withdrawal amount
    mov eax, [amountValue]
    sub [balance], eax

    ; Display successful withdrawal
    mov ecx, successMsg
    call print_string

    ; Display withdrawn amount
    mov ecx, withdrawnMsg
    call print_string

    mov eax, [amountValue]
    call print_number

    mov ecx, newline
    call print_string

    ; Display remaining balance
    mov ecx, remainingMsg
    call print_string

    mov eax, [balance]
    call print_number

    mov ecx, newline
    call print_string

    jmp exit_program

; ==================================================
; ERROR HANDLING
; ==================================================

access_denied:
    mov ecx, deniedMsg
    call print_string
    jmp exit_program

invalid_name:
    mov ecx, nameError
    call print_string
    jmp exit_program

invalid_amount:
    mov ecx, invalidMsg
    call print_string
    jmp exit_program

insufficient_funds:
    mov ecx, fundsMsg
    call print_string
    jmp exit_program

invalid_multiple:
    mov ecx, multipleMsg
    call print_string
    jmp exit_program

; ==================================================
; PROCEDURE: PRINT STRING
; ECX = address of null-terminated string
; ==================================================

print_string:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, ecx
    xor edx, edx

count_chars:
    cmp byte [esi + edx], 0
    je print_now

    inc edx
    jmp count_chars

print_now:
    mov eax, 4
    mov ebx, 1
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; ==================================================
; PROCEDURE: READ LINE
; EDI = destination, EBP = max length
; EAX = length or -1 on overflow
; ==================================================

read_line:
    push ebx
    push ecx
    push edx
    push esi

    xor esi, esi
    mov byte [overflowFlag], 0

read_next:
    mov eax, 3
    mov ebx, 0
    mov ecx, inputChar
    mov edx, 1
    int 0x80

    cmp eax, 1
    jne read_done

    mov al, [inputChar]

    cmp al, 10
    je read_done

    cmp al, 13
    je read_next

    cmp esi, ebp
    jae mark_overflow

    mov [edi + esi], al
    inc esi
    jmp read_next

mark_overflow:
    mov byte [overflowFlag], 1
    jmp read_next

read_done:
    mov byte [edi + esi], 0
    mov eax, esi

    cmp byte [overflowFlag], 0
    je read_return

    mov eax, -1

read_return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ==================================================
; PROCEDURE: ASCII TO INTEGER
; ESI = input string
; EAX = converted unsigned integer
; CF = 1 if invalid
; ==================================================

ascii_to_int:
    push ebx
    push ecx
    push edx
    push esi

    xor eax, eax
    mov ebx, 10

    cmp byte [esi], 0
    je convert_invalid

convert_loop:
    movzx edx, byte [esi]

    cmp dl, 0
    je convert_done

    cmp dl, '0'
    jb convert_invalid

    cmp dl, '9'
    ja convert_invalid

    sub edx, '0'
    push edx

    mul ebx
    pop ecx

    jc convert_invalid

    add eax, ecx
    jc convert_invalid

    inc esi
    jmp convert_loop

convert_done:
    clc
    jmp convert_return

convert_invalid:
    stc

convert_return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ==================================================
; PROCEDURE: PRINT UNSIGNED INTEGER
; EAX = number to print
; ==================================================

print_number:
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov edi, numberBuffer + 15
    mov byte [edi], 0
    mov ebx, 10

number_loop:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz number_loop

    mov ecx, edi
    call print_string

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; ==================================================
; EXIT PROGRAM
; ==================================================

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80
