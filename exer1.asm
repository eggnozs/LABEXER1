BITS 32
global _start

section .data
    clear_text db 27, '[2J', 27, '[H', 0
    menu db '----------------------------------', 10
         db 'MENU', 10, 10
         db '[A]dd', 10
         db '[S]ubtract', 10
         db '[M]ultiply', 10
         db '[D]ivide', 10
         db '----------------------------------', 10
         db 'Enter your choice: ', 0
    first_prompt db 10, 'Enter first number: ', 0
    second_prompt db 'Enter second number: ', 0
    sum_text db 10, 'The sum is ', 0
    difference_text db 10, 'The difference is ', 0
    product_text db 10, 'The product is ', 0
    quotient_text db 10, 'The quotient is ', 0
    remainder_text db ' with remainder ', 0
    retry_text db 10, 10, 'Do you want to try again (Y/N): ', 0
    choice_error db 'Invalid choice. Enter A, S, M, or D.', 10, 0
    number_error db 'Invalid number. Enter 0 to 99.', 10, 0
    retry_error db 'Please enter Y or N.', 10, 0
    zero_error db 10, 'Cannot divide by zero.', 0
    goodbye db 10, 'Program terminated.', 10, 0

section .bss
    input resb 4
    character resb 1
    digits resb 16
    choice resb 1
    first resd 1
    second resd 1

section .text
_start:
    call clear_screen

menu_loop:
    mov esi, menu
    call print_string
    call read_line
    cmp eax, 1
    jne bad_choice
    mov al, [input]
    and al, 0DFh
    cmp al, 'A'
    je valid_choice
    cmp al, 'S'
    je valid_choice
    cmp al, 'M'
    je valid_choice
    cmp al, 'D'
    je valid_choice

bad_choice:
    mov esi, choice_error
    call print_string
    jmp menu_loop

valid_choice:
    mov [choice], al
    mov esi, first_prompt
    call read_number
    mov [first], eax
    mov esi, second_prompt
    call read_number
    mov [second], eax

    cmp byte [choice], 'A'
    je do_add
    cmp byte [choice], 'S'
    je do_subtract
    cmp byte [choice], 'M'
    je do_multiply
    call divide_numbers
    jmp ask_again

do_add:
    call add_numbers
    jmp ask_again
do_subtract:
    call subtract_numbers
    jmp ask_again
do_multiply:
    call multiply_numbers

ask_again:
    mov esi, retry_text
    call print_string
    call read_line
    cmp eax, 1
    jne bad_retry
    mov al, [input]
    and al, 0DFh
    cmp al, 'Y'
    je restart
    cmp al, 'N'
    je terminate
bad_retry:
    mov esi, retry_error
    call print_string
    jmp ask_again

restart:
    call clear_screen
    jmp menu_loop

terminate:
    mov esi, goodbye
    call print_string
    mov eax, 1
    xor ebx, ebx
    int 80h

; Each arithmetic operation is a procedure called with CALL.
add_numbers:
    mov eax, [first]
    add eax, [second]
    mov esi, sum_text
    call print_string
    call print_number
    ret

subtract_numbers:
    mov eax, [first]
    sub eax, [second]
    mov esi, difference_text
    call print_string
    call print_number
    ret

multiply_numbers:
    mov eax, [first]
    imul eax, [second]
    mov esi, product_text
    call print_string
    call print_number
    ret

divide_numbers:
    cmp dword [second], 0
    je divide_zero
    mov eax, [first]
    xor edx, edx
    div dword [second]
    mov esi, quotient_text
    call print_string
    call print_number
    mov esi, remainder_text
    call print_string
    mov eax, edx
    call print_number
    ret
divide_zero:
    mov esi, zero_error
    call print_string
    ret

clear_screen:
    mov esi, clear_text
    call print_string
    ret

; ESI points to a zero-terminated string. Registers are preserved.
print_string:
    pushad
    mov ecx, esi
    xor edx, edx
count_characters:
    cmp byte [ecx + edx], 0
    je write_string
    inc edx
    jmp count_characters
write_string:
    mov eax, 4
    mov ebx, 1
    int 80h
    popad
    ret

; Read a whole line; return its length in EAX, or -1 if too long.
read_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    xor esi, esi
    xor edi, edi
read_character:
    mov eax, 3
    xor ebx, ebx
    mov ecx, character
    mov edx, 1
    int 80h
    cmp eax, 0
    jle terminate
    mov al, [character]
    cmp al, 10
    je line_done
    cmp al, 13
    je read_character
    cmp esi, 3
    jae line_too_long
    mov [input + esi], al
    inc esi
    jmp read_character
line_too_long:
    mov edi, 1
    jmp read_character
line_done:
    mov eax, esi
    test edi, edi
    jz line_return
    mov eax, -1
line_return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ESI is the prompt. Accept one or two decimal digits; return EAX.
read_number:
    push ebx
    push ecx
    push edx
    push edi
number_prompt:
    call print_string
    call read_line
    cmp eax, 1
    jl invalid_number
    cmp eax, 2
    jg invalid_number
    mov edi, eax
    mov ecx, input
    xor eax, eax
convert_digit:
    movzx edx, byte [ecx]
    cmp edx, '0'
    jb invalid_number
    cmp edx, '9'
    ja invalid_number
    sub edx, '0'
    imul eax, eax, 10
    add eax, edx
    inc ecx
    dec edi
    jnz convert_digit
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
invalid_number:
    push esi
    mov esi, number_error
    call print_string
    pop esi
    jmp number_prompt

; Convert signed EAX to decimal text, preserving all registers.
print_number:
    pushad
    mov edi, digits + 15
    mov byte [edi], 0
    xor ebp, ebp
    test eax, eax
    jns number_positive
    mov ebp, 1
    neg eax
number_positive:
    mov ebx, 10
next_digit:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz next_digit
    test ebp, ebp
    jz number_ready
    dec edi
    mov byte [edi], '-'
number_ready:
    mov esi, edi
    call print_string
    popad
    ret
