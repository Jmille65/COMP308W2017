.286
.model small
.stack 100h

.data
intEnter db "Enter a 1-digit (base 10) int: ",0; TIL '\0' is not a good null-terminator in x86...
aMinusB db "A - B = ",0
bMinusC db "B - C = ",0

.data?
A db ?
B db ?
C db ?

.code

; takes input from keyboard, returns char in dx while echoing to stdout
getche:; char getche(void)
  push ax; stores ax
  mov ah, 01h
  int 21h; char from stdin with echo
  mov dl, al; puts result in dl for return
  pop ax
  ret

; takes char from stack, prints to stdout
putch:; void putch(char)
  push ax
  push bx
  push dx
  mov bx, sp
  mov dx, ss:[bx+8]
  mov ah, 02h
  int 21h; write char to stdout
  pop dx
  pop bx
  pop ax
  ret

puts:; void puts(char*)
  push ax
  push bx
  push dx
  mov bx, sp
  mov bx, ss:[bx+8]; bx now holds pointer to first char
looper:
  mov dx, [bx]
  cmp dl, 0h; compares dx with 0
  je finishPuts; if this is null-terminated, jump to finishPuts
  push dx
  call putch
  pop dx
  add bx, 1
  jmp looper
finishPuts:
  pop dx
  pop bx
  pop ax
  ret

; puts char* in address given in arg w/ newline and null-termination
gets:; void gets(char*)
  push ax
  push bx
  push dx
  mov bx, sp
  mov bx, ss:[bx+8]; bx holds pointer to char* arg
getterLoop:
  call getche; dx holds new char
  mov [bx], dx; puts new char into memory
  add bx, 1; increments pointer
  cmp dl, 13d; if new char is enter/carriage return
  jnz getterLoop
; finish section
  mov dx, 0h
  mov [bx], dx; null-terminates
  pop dx
  pop bx
  pop ax
  ret

; int getInt(void) overwrites ax
getInt:
  push dx
  call getche; dx holds new char
  sub dx, 48d; converts from char to int
  mov ax, dx; puts int into ax for return
  mov ah, 0h
  pop dx
  ret

; ; void printInt(int) takes int from stack- largest value 10d
; printInt:
;   push ax
;   push bx
;   mov bx, sp
;   mov ax, ss:[bx+6]
;   add ax, 48d; converts to char
;   mov ah, 0h
;   push ax
;   call putch
;   pop ax
;   pop bx
;   pop ax
;   ret

; void printInt(int) takes int from stack
printInt:
  push ax
  push bx
  push cx
  mov bx, sp
  mov ax, ss:[bx+8]
  mov cx, 0h
intLooper:
  mov dx, 0h
  mov bx, 0Ah
  div bx; dx has remainder, ax has quotient
  mov bx, ax
  mov ax, dx
  mov dx, bx
  add ax, 30h; converts to char
  inc cx
  push ax
  ; call putch; at this point dx has quotient, ax has remainder + 30h
  mov ax, dx
  cmp ax, 0h; if quotient is 0, jump
  jne intLooper
printLooper:
  call putch
  pop ax; doesn't matter where
  dec cx
  cmp cx, 0h
  jne printLooper; if more characters in stack, will print them
  pop cx
  pop bx
  pop ax
  ret

start:
  mov ax, @data
  mov ds, ax

  ; prints int entry prompt
  lea ax, intEnter
  push ax
  call puts

  call getche
  lea bx, A
  mov dh, 0h
  mov ds:[bx], dx; address at A now contains inputted int A

  push 10d; newline
  call putch

  lea ax, intEnter
  push ax
  call puts

  call getInt; ax has B
  lea bx, B
  mov ah, 0h
  mov ds:[bx], ax; now B has int B in it

  push 10d
  call putch

  lea ax, intEnter
  push ax
  call puts

  call getInt; ax has C
  lea bx, C
  mov ah, 0h
  mov ds:[bx], ax; C now holds C

  push 10d
  call putch

  lea ax, aMinusB
  push ax
  call puts

  lea bx, ds:[A]
  mov ax, ds:[bx]
  lea bx, ds:[B]
  mov cx, ds:[bx]
  sub al, cl
  mov ah, 0h
  push ax
  call printInt

  push 10d
  call putch

  lea ax, bMinusC
  push ax
  call puts

  lea bx, ds:[B]
  mov ax, [bx]
  lea bx, ds:[C]; meh, why not, it's easy to keep track of
  mov cx, [bx]
  sub al, cl
  mov ah, 0h
  push ax
  call printInt

  mov ax, 4c00h
  int 21h
END start
