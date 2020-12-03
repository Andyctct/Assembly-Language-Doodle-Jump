#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Andy Wu, 1005908369
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

#TODO
#Have platforms auto generate in a range of distance away from each other
#Store where platforms are, redraw them as loop goes
#Implement collision with platforms
#Implement offbound action

.data
	displayAddress: .word 0x10008000 # top left pixel  
	skyColour: .word 0x10002000 # deep sky blue 
	doodlerColour: .word 0x10001000 # coral 
	platformColour: .word 0x10000000 # dark slate gray 
	platformStartRow: .word 0x00000100 
	platformStartColumn: .word 0x00010000
	rowMultiplier: .word 0x00002000 # 128, 32 units per row 
	columnMultiplier: .word 0x02000000 # 4, 1 units per column 
	doodlerArray: .space 36 # starts with the position of the doodler's left head and progresses in row major order
	upOrDown: .word 0x40000000
	halfScreen: .word 0x44444444 # stores row 15 of the screen, if the doodler is here, it stops moving and platforms start moving 
	deathRow: .word 0x60000000 # stores the first pixel of the bottom row of the screen, the death row for the doodler
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	li $t1, 0x00bfff # $t1 stores the deep sky blue colour code for the background
	sw $t1, skyColour
	li $t2, 0xff7f50 # $t2 stores the coral colour code for the doodler
	sw $t2, doodlerColour 
	li $t3, 0x2f4f4f # $t3 stores the dark slate gray colour code for the platforms
	sw $t3, platformColour 
	
	# initialize column multiplier, row multiplier, half screen, and death row constants
	addi $t6, $zero, 4
	sw $t6, columnMultiplier
	addi $t6, $zero, 128 
	sw $t6, rowMultiplier
	addi $t7, $zero, 15
	mult $t6, $t7
	mflo $t6 
	sw $t6, halfScreen
	addi $t7, $zero, 31
	mult $t6, $t7
	mflo $t6
	add $t6, $t6, $t0
	sw $t6, deathRow 
	
	# initialize up or down to up for the starting doodler
	addi $t6, $zero, 1
	sw $t6, upOrDown	
	
	lw $t4, displayAddress  # initialize t4 which stores the address for the pixel of the background that we are currently painting 

	# Loop to paint the background
paint_sky: beq $t4, 268472320, paint_starting_platforms #268472320 from display address plus 4096 (32 rows times 32 4 byte colours per row) 
                    sw $t1, 0($t4) # paint this address' pixel deep sky blue
                    addi $t4, $t4, 4 # update the address in t4 to the next pixel
                    j paint_sky
        
        #maybe need to clear t4 for future sky painting use ???? or set t4 to 0 before every sky paint call  
	li $t5, 0 #never gets executed?
	# Loop to paint the starting platforms
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
                          lw $t6, rowMultiplier # load row mult so we can multiply by the row to get to the pixel location
                          lw $t7, columnMultiplier # load column mult so we can multipy by the column to get to the pixel location 
                          lw $t8, platformStartRow 
                          lw $t9, platformStartColumn
                          mult $t6, $t8 # multiply the randomly generated row by the row multiplier 
                          mflo $t8 # move the row multiplied by the row multiplier into t8 
                          mult $t7, $t9 # multiply the randomly generated column by the column multiplier 
                          mflo $t7 # move the column multiplied by the column multiplier into t7 
                          add $t8, $t7, $t8 # add the final column and row result to get the platform starting pixel
                          add $t8, $t0, $t8 # add the platform starting pixel to the display address
                          sw $t3, 0($t8) # paint the platform
                          sw $t3, 4($t8) 
                          sw $t3, 8($t8)
                          sw $t3, 12($t8)
                          sw $t3, 16($t8)
                          sw $t3, 20($t8)
                          sw $t3, 24($t8)
                          addi $t5, $t5, 1 #increment the number of starting platforms by 1
                          j paint_starting_platforms 
		 	   
	# Loop to paint the starting doodler  		 
paint_starting_doodler: addi $t7, $zero, 0
			 sw $t2, 3644($t0) # paint the starting position doodler left head
                        addi $t6, $t0, 3644 # store the doodler left head starting position address in t6
                        sw $t6, doodlerArray($t7) # save the doodler left head starting position address in doodlerLeftHead
                        addi $t7, $t7, 4 # move to the next part of the doodler in the doodler array
                        
                        # pattern repeats for every part of the doodler
                        
                        sw $t2, 3648($t0) # doodler middle head
                        addi $t6, $t0, 3648 
                        sw $t6, doodlerArray($t7) 
                        addi $t7, $t7, 4
                        sw $t2, 3652($t0) # doodler right head 
                        addi $t6, $t0, 3652 
                        sw $t6, doodlerArray($t7)
                        addi $t7, $t7, 4                         
                        sw $t2, 3768($t0) # doodler left upper body
                        addi $t6, $t0, 3768 
                        sw $t6, doodlerArray($t7)
                        addi $t7, $t7, 4                        
                        sw $t2, 3784($t0) # doodler right upper body 
                        addi $t6, $t0, 3784
                        sw $t6, doodlerArray($t7)
                        addi $t7, $t7, 4
                        sw $t2, 3896($t0) # doodler left lower body
                        addi $t6, $t0, 3896 
                        sw $t6, doodlerArray($t7)  
                        addi $t7, $t7, 4                        
                        sw $t2, 3912($t0)
                        addi $t6, $t0, 3912 # doodler right lower body
                        sw $t6, doodlerArray($t7)
                        addi $t7, $t7, 4                        
                        sw $t2, 4028($t0) # doodler left foot
                        addi $t6, $t0, 4028
                        sw $t6, doodlerArray($t7)
                        addi $t7, $t7, 4                        
                        sw $t2, 4036($t0) # doodler right foot
                        addi $t6, $t0, 4036
                        sw $t6, doodlerArray($t7)

	# Loop to update the screen
loop: jal check_input # check input and link return address 
      jal check_collision
      jal update_platform_check # move platforms if necessary 
      
      li $v0, 32
      li $a0, 400
      syscall
      j loop
      
check_input: lw $t8, 0xffff0000	 # load whether the key was pressed, 1 if pressed, 0 if no
             # have to check whether moving up or down
             addi $a0, $zero, 128 # store the argument as moving down
             lw $t6, upOrDown
             beq $t6, $zero, skip_2_down
             addi $a0, $zero, -128  # store the argument as moving up 
skip_2_down: beq $t8, 0, move_doodler # check if there was no input 
             lw $t7, 0xffff0004 # load the ascii code of the pressed key
             addi $a0, $zero, -4 # store the argument as moving left 
             beq $t7, 106, move_doodler 
             addi $a0, $zero, 4 # store the argument as moving right 
             beq $t7, 107, move_doodler  
        
        # Function for doodler movement, a0 dictates which direction to move in, 128 = down, -128 = up, -4 = left, 4 = right 
move_doodler: 	addi $t7, $zero, 0
		lw $t6, doodlerArray($t7) # load the current left head address of the doodler into t6
              	sw $t1, 0($t6) # paint over the current left head position of the doodler
              	add $t6, $t6, $a0 # update the address of the left head
              	sw $t6, doodlerArray($t7) # save the updated address of the left head
              	sw  $t2, 0($t6) # paint the updated left head position of the doodler       
        	addi $t7, $t7, 4 # move to the next part of the doodler in the doodler array
        	 
              	# pattern repeats for every part of the doodler
              	
              	lw $t6, doodlerArray($t7) # doodler middle head
              	beq $a0, 4, safe_right # check if doodler is moving right and if so skip next step to avoid painting over newly drawn unit
              	sw $t1, 0($t6) 
    safe_right:	add $t6, $t6, $a0 
               	sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6) 
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right head
              	beq $a0, 4, safe_right_2 # check if doodler is moving right and if so skip next step to avoid painting over newly drawn unit
              	sw $t1, 0($t6) 
  safe_right_2:	add $t6, $t6, $a0 
  		sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6) 
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left upper body
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0 
              	sw $t6, doodlerArray($t7) 
              	sw $t2, 0($t6)           
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right upper body
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0
              	sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6)   
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left lower body
              	beq $a0, 128, safe_down # check if doodler is moving down and if so skip next step to avoid painting over newly drawn unit
              	sw $t1, 0($t6) 
     safe_down:	add $t6, $t6, $a0 
     		sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6)        
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right lower body
              	beq $a0, 128, safe_down_2 # check if doodler is moving down and if so skip next step to avoid painting over newly drawn unit
              	sw $t1, 0($t6) 
   safe_down_2:	add $t6, $t6, $a0
   		sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6)       
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left foot  
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0
              	sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right foot 
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0 
              	sw $t6, doodlerArray($t7)
              	sw $t2, 0($t6)
              	jr $ra 
 
check_collision: addi $t6, $zero, 28 # store offset for doodler left foot  
                 lw $t7, doodlerArray($t6) # load doodler left foot address into t7
                 lw $t6, deathRow  
                 bge $t7, $t6, Exit # checks if doodler left foot is at bottom row of screen, if so terminate the program   
                 addi $t8,  $t7, 128 # put address of unit below doodler left foot into t8 
                 lw $t6, 0($t8) # load colour stored at unit below doodler left foot 
                 bne $t6, $t2, no_left_collision # if unit below doodler left foot is not a platform, jump to no left collision
                 addi $t6, $zero, -128 # store up velocity in t6 
                 sw $t6, upOrDown # save up velocity in current direction 
                 jr $ra # jump to return address if already collided 
                 
                   #repeat above instructions for doodler right foot     
no_left_collision: addi $t6, $zero, 32 
                   lw $t7, doodlerArray($t6)
                   addi $t8, $t7, 128  
                   lw $t6, 0($t8)
                   beq $t8, $t7, no_collision
                   addi $t6, $zero, -128  
                   sw $t6, upOrDown 
     no_collision: jr $ra  

update_platform_check: lw $t7, doodlerArray($zero)
                       lw $t6, halfScreen
                       ble $t7, $t6, move_platforms
                       jr $ra   
       move_platforms:  
                       
redraw: 

sleep:                   

Exit:
li $v0, 10 # terminate the program gracefully
syscall
