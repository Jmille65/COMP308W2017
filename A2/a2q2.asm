.286
.model small
.stack 100h

.data

line_break db 13,10,0

SVGA_Info STRUC
  Signature			dd ?
	VersionL			db ?
	VersionH			db ?
	OEMStringPtr			dd ?
	CapableOf			dd ?
	VidModePtr			dd ?
	TotalMemory			dw ?
	OEMSoftwareVersion		dw ?
	VendorName			dd ?
	ProductName			dd ?
	ProductRevisionStr		dd ?
	Reserved			db 512 DUP(?)
SVGA_Info ENDS

SVGA_ModeInfo STRUC
	ModeAttributes			dw ?
	WinAAttributes			db ?
	WinBAttributes			db ?
	WinGranularity			dw ?
	WinSize				dw ?
	WinASegment			dw ?
	WinBSegment			dw ?
	WinFuncPtr			dd ?
	BytesPerScanLine		dw ?
	XResolution			dw ?
	YResolution			dw ?
	XCharSize			db ?
	YCharSize			db ?
	NumberOfPlanes			db ?
	BitsPerPixel			db ?
	NumberOfBanks			db ?
	MemoryModel			db ?
	BankSize			db ?
	NumberOfImagePages		db ?
	Reserved1			db ?
	RedMaskSize			db ?
	RedFieldPosition		db ?
	GreenMaskSize			db ?
	GreenFieldPosition		db ?
	BlueMaskSize			db ?
	BlueFieldPosition		db ?
	RsvdMaskSize			db ?
	DirectColorModeInfo		db ?
	Reserved2			db 216 DUP(?)
SVGA_ModeInfo ENDS

SVGA_I SVGA_Info <>
SVGA_MI SVGA_ModeInfo <>

; errors:
vga_error db "Error getting vga info",13,10,0
vga_mode_error db "Error getting vga mode info",13,10,0
vga_detect_error db "Error getting current mode",13,10,0

; requested IO fields:
svga_section_title db "SVGA INFO",13,10,0
svga_mode_section_title db "SVGA MODE INFO",13,10,0

sig db "Signature: ",0
verl db "VersionL: ",0
verh db "VersionH: ",0
osp db "OEMStringPtr: ",0
xres db "XResolution: ",0
yres db "YResolution: ",0
xcs db "XCharSize: ",0
ycs db "YCharSize: ",0
bpp db "BitsPerPixel: ",0
nob db "NumberOfBanks: ",0
memmod db "MemoryModel: ",0

.code

get_vga_info:
  push bp
  mov bp, sp
  push ax
  push es
  push di

  mov es, [bp+6]
  mov di, [bp+4]
  ; mov ax, ds
  ; mov es, ax
  ; mov di, offset SVGA_I
  mov ax, 4f00h
  int 10h

  cmp ax, 004fh
  je get_vga_info_success
  push offset vga_error
  call puts
  add sp, 2
get_vga_info_success:
  pop di
  pop es
  pop ax
  pop bp
  ret

get_vga_mode_info:
  push bp
  mov bp, sp
  push bx
  push cx
  push ax
  push es
  push di

  mov ax, 4F03h; return current vbe mode
  cmp ax, 004fh
  je detect_success
  push offset vga_detect_error
  call puts
  add sp, 2
detect_success:
  mov bx, 0h
  int 10h

  mov cx, bx; moves current vbe mode info into register for 01h
  mov cx, 0101h
  ; mov ax, ds
  ; mov es, ax
  ; mov di, offset SVGA_MI
  mov es, [bp+6]
  mov di, [bp+4]
  mov ax, 4f01h
  int 10h

  cmp ax, 004fh
  je get_vga_mode_info_success
  push offset vga_mode_error
  call puts
  add sp, 2
get_vga_mode_info_success:
  pop di
  pop es
  pop ax
  pop cx
  pop bx
  pop bp
  ret

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

  push ds
  push offset SVGA_I
  call get_vga_info

  push ds
  push offset SVGA_MI
  call get_vga_mode_info

  push offset line_break
  call puts
  push offset svga_section_title
  call puts

  push offset sig
  call puts
  mov bx, offset SVGA_I
  push bx
  call puts
  push offset line_break
  call puts

  push offset verl
  call puts
  mov ax, ds:[bx+4]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset verh
  call puts
  mov ax, ds:[bx+5]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset osp
  call puts
  mov bx, OEMStringPtr
  mov ax, ds:[bx+6]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset line_break
  call puts
  push offset svga_mode_section_title
  call puts

  push offset xres
  call puts
  mov bx, offset SVGA_MI
  mov ax, ds:[bx+1Ch]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset yres
  call puts
  mov ax, ds:[bx+20h]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset xcs
  call puts
  mov bx, XCharSize
  mov ax, ds:[bx]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset ycs
  call puts
  mov bx, YCharSize
  mov ax, ds:[bx]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset bpp
  call puts
  mov bx, BitsPerPixel
  mov ax, ds:[bx]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset nob
  call puts
  mov bx, NumberOfBanks
  mov ax, ds:[bx]
  push ax
  call printInt
  push offset line_break
  call puts

  push offset memmod
  call puts
  mov bx, MemoryModel
  mov ax, ds:[bx]
  push ax
  call printInt
  push offset line_break
  call puts

  mov ax, 4c00h
  int 21h
END start
