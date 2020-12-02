# Doodle Jump 
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress: .word 0x10008000
	skyColour: .word 0x10002000
	doodlerColour: .word 0x10001000
	platformColour: .word 0x10000000
	platformStartRow: .word 0x00000100
	platformStartColumn: .word 0x00010000
	rowMultiplier: .word 0x00002000
	columnMultiplier: .word 0x02000000
	doodlerLeftHead: .word 0x00300000
	doodlerRightHead: .word 0x00300004
	doodlerLeftUpperBody: .word 0x00300008
	doodlerRightUpperBody: .word 0x00300012
	doodlerLeftLowerBody: .word 0x00300016
	doodlerRightLowerBody: .word 0x00300020
	doodlerLeftFoot: .word 0x00300024
	doodlerRightFoot: .word 0x00300028

.text
	lw $t0, displayAddress # $t0 stores the base address for display
	li $t1, 0x00bfff # $t1 stores the deep sky blue colour code for the background
	sw $t1, skyColour
	 $t2, 0xff7f50 # $t2 stores the coral colour code for the doodler
	sw $t2, doodlerColour 
	li $t3, 0x2f4f4f # $t3 stores the dark slate gray colour code for the platforms
	sw $t3, platformColour

	lw $t4, displayAddress  # initialize t4 which stores the address for the pixel of the background that we are currently painting 

	#Loop to paint the background
paint_starting_sky: beq $t4, 268472320, paint_starting_platforms #268472320 from display address plus 4096 (32 rows times 32 4 byte colours per row) 
	   sw $t1, 0($t4) # paint this address' pixel deep sky blue
	   addi $t4, $t4, 4 # update the address in t4 to the next pixel
	   j paint_starting_sky

	li $t5, 0
	#Loop to paint the starting platforms
paint_starting_platforms: beq $t5, 3, paint_starting_doodler #go to paint starting doodler after painting first 3 platforms
                          li $v0, 42 # randomly generate the row of the platform
                          li $a0, 0
                          li $a1, 28 #28 because we don't want platforms where the starting doodler is
                          syscall
                          sw $a0, platformStartRow # store the row into platformStartRow in memory
                          li $v0, 42 # randomly generate the starting column of the row
                          li $a0, 0
                          li $a1, 26 # 25 because platforms are 7 units wide
                          syscall 
                          sw $a0, platformStartColumn # store the column into platformStartColumn in memory  
                          addi $t6, $zero, 128 # store 128 into t6 so we can multiply it by the row to get to the pixel location
                          addi $t7, $zero, 4 #store 4 into t7 so we can multiply it by the column to get to the pixel location 
                          lw $t8, platformStartRow 
                          lw $t9, platformStartColumn
                          mult $t6, $t8 # multiply the randomly generated row by the row multiplier 
                          mflo $t8 # move the row multiplied by the row multiplier into t8 
                          mult $t7, $t9 # multiply the randomly generated column by the column multiplier 
                          mflo $t7 # move the column multiplied by the column multiplier into t7 
                          add $t8, $t7, $t8 # add the final column and row result to get the platform starting pixel
                          addi $t8, $t8, 512 #add 128 x 4 because don't want starting platforms where starting doodler will be : first 4 rows
                          add $t8, $t0, $t8 # add the platform starting pixel to the display address
                          sw $t3, 0($t8) # paint the platform
                          sw $t3, 4($t8) 
                          sw $t3, 8($t8)
                          sw $t3, 12($t8)
                          sw $t3, 16($t8)
                          sw $t3, 20($t8)
                          sw $t3, 24($t8)
                          addi $t5, $t5, 0 #increment the number of starting platforms by 1
                          j paint_starting_platforms 
		 	   
	#Loop to paint the starting doodler  		 
paint_starting_doodler: sw $t2, 60($t0) # paint the starting position doodler head
                        sw $t2, 64($t0) # paint the starting position doodler head
                        sw $t2, 68($t0) # paint the starting position doodler head 
                        sw $t2, 184($t0) # paint the starting position doodler body 
                        sw $t2, 200($t0) # paint the starting position doodler body
                        sw $t2, 312($t0) # paint the starting position doodler body
                        sw $t2, 328($t0) # paint the starting position doodler body
                        sw $t2, 444($t0) # paint the starting position doodler feet
                        sw $t2, 452($t0) # paint the starting position doodler feet

paint_sky:

paint_platform:

paint_doodler:

move: lw $t8, 0xffff0000	 
      beq $t8, 0, no_input
      lw $t7, 0xffff0004
      beq $t7, 106, move_left
      beq $t7, 107, move_right
      beq $t7, 115, restart
        
no_input: 
 
	#Loop to update the screen
loop: 

Exit:
li $v0, 10 # terminate the program gracefully
syscall