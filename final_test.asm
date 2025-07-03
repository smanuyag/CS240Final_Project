.data
imageWidth:  .word 8
imageHeight: .word 8

ColorTable:
    .word 0x000000   # 0 = 'k' = black
    .word 0xFFA321   # 1 = 'o' = orange
    .word 0x666666   # 2 = 'g' = gray
    .word 0xFFFFFF   # 3 = 'w' = white
    .word 0x00B7EF   # 4 = 'b' = blue
    .word 0xFFA3B1   # 5 = 'p' = pink

# Mapping ASCII letters to color indices
# ASCII offset starts at 98 ('b'), and 'b' is index 0

# -1 is for the colors that aren't used
# the offset/index is the ASCII value - 98
letterToColorCompressed:
    .byte 4      # 98 'b' - blue index 4
    .byte -1     # 99
    .byte -1     # 100
    .byte -1     # 101
    .byte -1     # 102
    .byte -1     # 103
    .byte 2      # 104 'g' - gray index 2
    .byte -1     # 105
    .byte -1     # 106
    .byte 0      # 107 'k' - black index 0
    .byte -1     # 108
    .byte -1     # 109
    .byte -1     # 110
    .byte 1      # 111 'o' - organe index 1
    .byte 5      # 112 'p' - pink index 5
    .byte -1     # 113
    .byte -1     # 114
    .byte -1     # 115
    .byte -1     # 116
    .byte -1     # 117
    .byte -1     # 118
    .byte 3      # 119 'w' - white index 3

# Pixel art images (8x8) - 2D arrays to keep track of which color goes where
expectedPixels_cat:
    .byte 'b','k','b','b','b','b','k','b'
    .byte 'k','p','k','b','b','k','p','k'
    .byte 'k','p','w','k','k','w','p','k'
    .byte 'k','w','w','w','w','w','w','k'
    .byte 'k','w','k','w','w','k','w','k'
    .byte 'k','w','w','p','p','w','w','k'
    .byte 'b','k','w','w','w','w','k','b'
    .byte 'b','b','k','k','k','k','b','b'
    

expectedPixels_duck:
    .byte 'b','b','b','b','b','b','b','b'
    .byte 'b','b','w','w','b','b','b','b'
    .byte 'b','o','w','w','b','b','b','b'
    .byte 'b','b','b','w','b','b','w','b'
    .byte 'b','b','b','w','w','w','w','b'
    .byte 'b','b','b','w','w','w','w','b'
    .byte 'b','b','b','b','o','b','o','b'
    .byte 'b','b','b','b','b','b','b','b'

expectedPixels_bunny:
    .byte 'b','w','b','b','b','b','w','b'
    .byte 'w','p','w','b','b','w','p','w'
    .byte 'w','p','w','b','b','w','p','w'
    .byte 'w','w','w','w','w','w','w','w'
    .byte 'w','w','k','w','w','k','w','w'
    .byte 'p','p','w','k','k','w','p','p'
    .byte 'w','w','w','w','w','w','w','w'
    .byte 'w','w','w','w','w','w','w','w'
    
    
# prompts
userMessage1: .asciiz "Welcome to Pixel Art!\nWhich picture would you like to color in?\n"
userMessage2: .asciiz "\nDuck (1)\nCat (2)\nBunny (3)\nSelect a number: "
userConfirm:  .asciiz "You chose: "
colorPrompt:  .asciiz "Enter this letter to color the pixel: "
newLine:      .asciiz "\n"

        
.text 
.globl main


main:
    # print welcome
    li $v0, 4
    la $a0, userMessage1
    syscall

    # print choices
    li $v0, 4
    la $a0, userMessage2
    syscall

    # read user input
    li $v0, 5
    syscall
    move $t0, $v0

    # confirm choice
    li $v0, 4
    la $a0, userConfirm
    syscall

    li $v0, 1            #user's choice is moved to the argument register
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, newLine
    syscall

    # branch to selected image
    li $t1, 1
    beq $t0, $t1, choose_duck
    li $t1, 2
    beq $t0, $t1, choose_cat
    li $t1, 3
    beq $t0, $t1, choose_bunny

    # tells system this is the end to prevent recursion 
    li $v0, 10  
    syscall

# loads in the 2D arrays
choose_duck:
    la $s0, expectedPixels_duck
    j DrawSelected

choose_cat:
    la $s0, expectedPixels_cat
    j DrawSelected

choose_bunny:
    la $s0, expectedPixels_bunny
    j DrawSelected

# will draw each pixel in accordance with the letter from the user and 2D array
DrawSelected:
    li $s1, 0                  # $s1 = y = row index - starts at 0
    li $t6, 8                  # width = 8, height = 8

outer_loop:
    li $s2, 0                  # $s2 = x = column index - starts at 0

inner_loop:
    # finds which letter should be input 
    mul $t0, $s1, $t6          # t0 = y * width - get proper row
    add $t0, $t0, $s2          # t0 = y * width + x - get proper column in said row

    add $t1, $s0, $t0          # t1 = address of current pixel letter
    lb  $t2, 0($t1)            # t2 = expected letter
    
    # tells user to enter in the letter
    li $v0, 4
    la $a0, colorPrompt     
    syscall

    li $v0, 11              # print the letter
    move $a0, $t2
    syscall

    li $v0, 11              # prints colon after the letter the user needs to input
    li $a0, ':'
    syscall

    li $v0, 11
    li $a0, ' '
    syscall

    li $v0, 4
    la $a0, newLine
    syscall


wait_input:
    li $v0, 12              # read the letter the user input
    syscall
    move $t3, $v0           # t3 = user's input 

   
    bne $t3, $t2, wait_input  # checks if the letter matches the 2D array, and waits until it's correct if not

    # Convert to color index
    li $t4, 98                # base ASCII - 'b' (98)
    sub $t7, $t3, $t4         # t7 holds the offset (ASCII - 98)
    bltz $t7, wait_input      # checks if the offset come before the start of the ASCII table
    li $t8, 21                # length of the table in letterToColorCompressed
    bgt $t7, $t8, wait_input  # checks if the offset is out of the ASCII table's range

    la $t9, letterToColorCompressed  # gets address of the table in letterToColorCompressed
    add $t9, $t9, $t7       # offset = ASCII - 98
    lb  $a2, 0($t9)         # loads the color index (load byte - character from user) into $a2
    bltz $a2, wait_input    # if offset in tbale is -1, the color is invalid


    # draw the pixel (x and y passed to DrawDot)
    move $a0, $s2              # x
    move $a1, $s1              # y
    jal DrawDot

    # goes to the next column 
    addi $s2, $s2, 1
    li   $t5, 8                # width = 8
    blt  $s2, $t5, inner_loop  # if x < 8, loop again

    # goes to the next row
    addi $s1, $s1, 1
    li   $t5, 8                # height = 8
    blt  $s1, $t5, outer_loop  # if y < 8, next row

    # end
    li $v0, 10
    syscall


    
    
CalculateAddress:
    li $v0, 0x10040000       # base address of display - top left
    sll $t2, $a0, 2          # x * 4 (4 bytes per pixel)
    li  $t4, 32              # number of bytes per row = 8 pixels * 4 bytes
    mul $t3, $a1, $t4        # y * 32 ^ - this is because y moves through rows that are 32 bytes each
    add $v0, $v0, $t2        # base address + x offset
    add $v0, $v0, $t3        # base + x offset + y offset = pixel address
    jr $ra

    
GetColor:
    la $t0, ColorTable       # gets the ColorTable base address
    sll $a2, $a2, 2          # color index * 4 - color value is of type word (4 bytes)
    add $a2, $a2, $t0        # a2 = color's address
    lw $v1, 0($a2)           # load color's value (hex value) into v1, offset is 0 since $a2 is the correct address already
    
    jr $ra
    
DrawDot:
    # will be done/ignore pixels the user tries to access outside of the 8 pixel range (or 0-7 index)
    bltz $a0, doneDrawingDot
    bltz $a1, doneDrawingDot
    bgt $a0, 7, doneDrawingDot
    bgt $a1, 7, doneDrawingDot
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal CalculateAddress     # get memory address of the current pixel
    jal GetColor             # get the color index
    
    sw $v1, 0($v0)           # stores color in the memory address
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    doneDrawingDot:
        jr $ra


