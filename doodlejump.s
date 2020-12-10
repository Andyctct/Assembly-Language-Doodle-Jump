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
# - Milestone 4
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - 
#
#####################################################################

#TODO
# Maybe add more randomness to platform generator
# Maybe change offbound action to same row wrapping
# Maybe change scoring algorithm? Current algorithm counts platforms landed on, can abuse by staying on one platform. Other option is 
# number of platforms that disappear off the map, downside is score will never be 0, 1, or 2 because of the initial up movement.

.data
	displayAddress: .word 0x10008000 # top left pixel  
	skyColour: .word 0x10002000 # light sky blue 
	doodlerColour: .word 0x10001000 # coral 
	platformColour: .word 0x10000000 # dark slate gray 
	platformStartRow: .word 0x00000100 # the randomly generated starting row of the platform we are initializing
	platformStartColumn: .word 0x00010000 # the randomly generated column of the platform we are initializing
	platformOne: .space 28 # the starting pixel of the first platform, first being the highest platform
	platformTwo: .space 28 # the starting pixel of the second platform
	platformThree: .space 28 # the starting pixel of the third platform
	platformFour: .space 28 # the starting pixel of the fourth platform
	rowMultiplier: .word 0x00002000 # 128, 32 units per row 
	columnMultiplier: .word 0x02000000 # 4, 1 units per column 
	doodlerArray: .space 36 # starts with the position of the doodler's left head and progresses in row major order
	jumpTime: .word 0x40000004 # how many units the doodler has of its jump left  
	halfScreen: .word 0x44444444 # stores row 15 of the screen, if the doodler is here, it stops moving and platforms start moving 
	deathRow: .word 0x60000000 # stores the first pixel of the bottom row of the screen, the death row for the doodler
	score: .word 0x64000000 # stores the score of the player
	
.text
	lw $t0, displayAddress # $t0 stores the base address for display
	li $t1, 0x87cefa # $t1 stores the light sky blue colour code for the background
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
	lw $t8, displayAddress
	add $t6, $t8, $t6 
	sw $t6, halfScreen
	addi $t6, $zero, 128
	addi $t7, $zero, 31
	mult $t6, $t7
	mflo $t6
	add $t6, $t6, $t0
	sw $t6, deathRow 

restart:      jal draw_start_screen
start_screen: lw $t8, 0xffff0000 # load whether the key was pressed, 1 if pressed, 0 if no
              beq $t8, 1, start_check # if a key was pressed check if it was the start button
              j start_screen # keep checking for a key press
 start_check: lw $t7, 0xffff0004 # load the ascii code of the pressed key if any
              beq $t7, 115, start_sequence # go to starting sequence if start key is pressed
              j start_screen # keep waiting for the start key to be pressed
		
start_sequence:		
	# initialize up movement for the starting doodler and score of the player
	sw $zero, score
	addi $t6, $zero, 25
	sw $t6, jumpTime

	# draw the sky
	jal draw_sky 
	
        # draw the starting platforms 
        addi $a2, $zero, 1 # pass the max range of the rows to be y, rng is exclusive
        addi $a3, $zero, 31  # pass the row range to be x to x + y, x in this case is 28 
        jal draw_random_platform # draw the platform and return, then repeat for the other 3 starting platforms
        addi $a2, $zero, 1 
        addi $a3, $zero, 23
        jal draw_random_platform
        addi $a2, $zero, 1
        addi $a3, $zero, 15
        jal draw_random_platform
        addi $a2, $zero, 1 
        addi $a3, $zero, 7
        jal draw_random_platform
        jal platforms_check
        
        # draw the starting doodler                  	 
        addi $t7, $zero, 0 
        sw $t2, 3644($t0) # draw the starting position doodler left head
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
        sw $t2, 3912($t0) # doodler right lower body
        addi $t6, $t0, 3912 
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
loop: jal check_input # check for keyboard input 
      # combine both collisions into one collision check?
      jal check_plat_collision # check for platform collision 
      #jal check_wall_collision # check for wall collision
      jal update_platform_check # move platforms if necessary 
      jal redraw_screen # redraw the screen 
      
      # sleep the program for 32 milliseconds 
      li $v0, 32
      li $a0, 30
      syscall
      j loop 
             
             # can generalize the directional velocities if needed      		
check_input: lw $t8, 0xffff0000	 # load whether the key was pressed, 1 if pressed, 0 if no
             lw $t6, jumpTime # load the amount of time left for the doodler to fly
             addi $a0, $zero, 128 # store moving down as argument
             ble $t6, 0, str8_down # if jump time is 0 or less, move doodler with argument down 
             addi $a0, $zero, -128 # store moving up as argument  
  str8_down: beq $t8, 0, update_doodler # check if there was no input, if so then move doodler with up or down argument
             lw $t7, 0xffff0004 # load the ascii code of the pressed key
    check_j: beq $t7, 106, input_j # check if input is j
    check_k: beq $t7, 107, input_k # check if input is k 
             j update_doodler # if input is neither j or k, jump to move doodler with up or down argument 
    input_j: addi $a0, $zero, -12 # store the argument as moving left 
             j update_doodler # jump to move doodler with left argument
    input_k: addi $a0, $zero, 12 # store the argument as moving right 
             j update_doodler # jump to move doodler with right argument 
             
                               
        # Function for doodler movement, a0 dictates which direction to move in, 128 = down, -128 = up, -4 = left, 4 = right 
update_doodler: addi $t7, $zero, 0 # index for the doodler array
		lw $t6, doodlerArray($t7) # load the current left head address of the doodler into t6
              	sw $t1, 0($t6) # draw over the current left head position of the doodler
              	add $t6, $t6, $a0 # update the address of the left head
              	sw $t6, doodlerArray($t7) # save the updated address of the left head  
        	addi $t7, $t7, 4 # move to the next part of the doodler in the doodler array
        	 
              	# pattern repeats for every part of the doodler
              	lw $t6, doodlerArray($t7) # doodler middle head
              	beq $a0, 4, safe_right # check if doodler is moving right and if so skip next step to avoid drawing over newly drawn unit
              	sw $t1, 0($t6) 
    safe_right:	add $t6, $t6, $a0 
               	sw $t6, doodlerArray($t7)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right head
              	beq $a0, 4, safe_right_2 # check if doodler is moving right and if so skip next step to avoid drawing over newly drawn unit
              	sw $t1, 0($t6) 
  safe_right_2:	add $t6, $t6, $a0 
  		sw $t6, doodlerArray($t7)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left upper body
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0 
              	sw $t6, doodlerArray($t7)       
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right upper body
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0
              	sw $t6, doodlerArray($t7)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left lower body
              	beq $a0, 128, safe_down # check if doodler is moving down and if so skip next step to avoid drawing over newly drawn unit
              	sw $t1, 0($t6) 
     safe_down:	add $t6, $t6, $a0 
     		sw $t6, doodlerArray($t7)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right lower body
              	beq $a0, 128, safe_down_2 # check if doodler is moving down and if so skip next step to avoid drawing over newly drawn unit
              	sw $t1, 0($t6) 
   safe_down_2:	add $t6, $t6, $a0
   		sw $t6, doodlerArray($t7)    
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler left foot  
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0
              	sw $t6, doodlerArray($t7)
              	addi $t7, $t7, 4
              	lw $t6, doodlerArray($t7) # doodler right foot 
              	sw $t1, 0($t6) 
              	add $t6, $t6, $a0 
              	sw $t6, doodlerArray($t7)
              	jr $ra 
              	
draw_start_screen: lw $t4, displayAddress  # initialize t4 which stores the address for the pixel of the background that we are currently drawing 
                   addi $t6, $zero, 0x1AE867   
 next_pixel_start: beq $t4, 268472320, title_images #268472320 from display address plus 4096 (32 rows times 32 4 byte colours per row) 
                   sw $t6, 0($t4) # draw this address' pixel deep sky blue
                   addi $t4, $t4, 4 # update the address in t4 to the next pixel
                   j next_pixel_start
     title_images: # draw the starting doodler                  	 
                   sw $t2, 3644($t0) # draw the starting position doodler left head
                   # pattern repeats for every part of the doodler
                   sw $t2, 3648($t0) # doodler middle head
                   sw $t2, 3652($t0) # doodler right head                    
                   sw $t2, 3768($t0) # doodler left upper body         
                   sw $t2, 3784($t0) # doodler right upper body 
                   sw $t2, 3896($t0) # doodler left lower body         
                   sw $t2, 3912($t0) # doodler right lower body                
                   sw $t2, 4028($t0) # doodler left foot
                   sw $t2, 4036($t0) # doodler right foot
                    
                   # write out the doodler jump title words 
                   addi $t6, $zero, 0xE81AA0
                   # draw out D
                   sw $t6, 644($t0)
                   sw $t6, 648($t0)
                   sw $t6, 652($t0)
                   sw $t6, 784($t0)
                   sw $t6, 912($t0)
                   sw $t6, 1040($t0)
                   sw $t6, 1164($t0)
                   sw $t6, 1160($t0)
                   sw $t6, 1156($t0)
                   sw $t6, 1028($t0)
                   sw $t6, 900($t0)     
                   sw $t6, 772($t0)
                   
                   # draw out O twice
                   sw $t6, 668($t0)
                   sw $t6, 672($t0)    
                   sw $t6, 676($t0)
                   sw $t6, 792($t0)
                   sw $t6, 920($t0)
                   sw $t6, 1048($t0)
                   sw $t6, 1180($t0)
                   sw $t6, 1184($t0)
                   sw $t6, 1188($t0)
                   sw $t6, 808($t0)
                   sw $t6, 936($t0)
                   sw $t6, 1064($t0)
                    
                   sw $t6, 692($t0)
                   sw $t6, 696($t0)    
                   sw $t6, 700($t0)
                   sw $t6, 816($t0)
                   sw $t6, 944($t0)
                   sw $t6, 1072($t0)
                   sw $t6, 1204($t0)
                   sw $t6, 1208($t0)
                   sw $t6, 1212($t0)
                   sw $t6, 832($t0)
                   sw $t6, 960($t0)
                   sw $t6, 1088($t0)
                    
                   # draw out D again
                   sw $t6, 712($t0)
                   sw $t6, 716($t0)
                   sw $t6, 720($t0)
                   sw $t6, 852($t0)
                   sw $t6, 980($t0)
                   sw $t6, 1108($t0)
                   sw $t6, 1232($t0)
                   sw $t6, 1228($t0)
                   sw $t6, 1224($t0)
                   sw $t6, 1096($t0)
                   sw $t6, 968($t0)     
                   sw $t6, 840($t0)
                   
                   # draw out L
                   sw $t6, 1244($t0)
                   sw $t6, 1116($t0)
                   sw $t6, 988($t0)     
                   sw $t6, 860($t0)
                   sw $t6, 732($t0)
                   sw $t6, 1248($t0)
                   sw $t6, 1252($t0)
                   sw $t6, 1256($t0)
                   
                   # draw out E
                   sw $t6, 1264($t0)
                   sw $t6, 1136($t0)
                   sw $t6, 1008($t0)     
                   sw $t6, 880($t0)
                   sw $t6, 752($t0)
                   sw $t6, 756($t0)
                   sw $t6, 760($t0)
                   sw $t6, 1012($t0)
                   sw $t6, 1016($t0)               
                   sw $t6, 1268($t0)
                   sw $t6, 1272($t0)
                   
                   # draw out J
                   #sw $t6, 1444($t0)
                   sw $t6, 1444($t0)
                   sw $t6, 1572($t0)
                   sw $t6, 1700($t0)
                   sw $t6, 1828($t0)
                   sw $t6, 1952($t0)
                   sw $t6, 1948($t0)
                   sw $t6, 1816($t0)
                    
                   # draw out U                    
                   sw $t6, 1452($t0)
                   sw $t6, 1580($t0)
                   sw $t6, 1708($t0)
                   sw $t6, 1836($t0)
                   sw $t6, 1968($t0)
                   sw $t6, 1972($t0)
                   sw $t6, 1572($t0)
                   sw $t6, 1700($t0)
                   sw $t6, 1464($t0)
                   sw $t6, 1592($t0)
                   sw $t6, 1720($t0)
                   sw $t6, 1848($t0)
                   sw $t6, 1572($t0)
                   sw $t6, 1700($t0)
                   
                   # draw out M
                   sw $t6, 1472($t0)
                   sw $t6, 1600($t0)
                   sw $t6, 1728($t0)
                   sw $t6, 1856($t0)
                   sw $t6, 1984($t0)
                   sw $t6, 1604($t0)
                   sw $t6, 1736($t0)
                   sw $t6, 1612($t0)
                   sw $t6, 1488($t0)
                   sw $t6, 1616($t0)
                   sw $t6, 1744($t0)
                   sw $t6, 1872($t0)
                   sw $t6, 2000($t0)
                   
                   # draw out P
                   sw $t6, 1496($t0)
                   sw $t6, 1624($t0)
                   sw $t6, 1752($t0)
                   sw $t6, 1880($t0)
                   sw $t6, 2008($t0)
                   sw $t6, 1500($t0)
                   sw $t6, 1504($t0)
                   sw $t6, 1636($t0)
                   sw $t6, 1760($t0)
                   sw $t6, 1756($t0)
                                        
                   jr $ra
                   
draw_end_screen: lw $t4, displayAddress  # initialize t4 which stores the address for the pixel of the background that we are currently drawing 
                 addi $t6, $zero, 0xB81818 
 next_pixel_end: beq $t4, 268472320, Ending_images #268472320 from display address plus 4096 (32 rows times 32 4 byte colours per row) 
                 sw $t6, 0($t4) # draw this address' pixel deep sky blue
                 addi $t4, $t4, 4 # update the address in t4 to the next pixel
                 j next_pixel_end
  Ending_images: # draw a greyed out starting doodler
                 addi $t6, $zero, 0xC8B9AA                  	 
                 sw $t6, 3644($t0) # draw the starting position doodler left head
                 # pattern repeats for every part of the doodler
                 sw $t6, 3648($t0) # doodler middle head
                 sw $t6, 3652($t0) # doodler right head                    
                 sw $t6, 3768($t0) # doodler left upper body         
                 sw $t6, 3784($t0) # doodler right upper body 
                 sw $t6, 3896($t0) # doodler left lower body         
                 sw $t6, 3912($t0) # doodler right lower body                
                 sw $t6, 4028($t0) # doodler left foot
                 sw $t6, 4036($t0) # doodler right foot
                 
                 # draw the Ending background, death face and gg 
                 addi $t6, $zero, 0xE7CD14 # colour for gg
                 # draw the x eyes
                 sw $zero, 436($t0)
                 sw $zero, 560($t0)   
                 sw $zero, 684($t0)
                 sw $zero, 692($t0)
                 sw $zero, 428($t0)   
                 sw $zero, 460($t0) 
                 sw $zero, 592($t0)               
                 sw $zero, 724($t0)        
                 sw $zero, 716($t0) 
                 sw $zero, 468($t0)
                 # draw the frown
                 sw $zero, 1084($t0)
                 sw $zero, 1088($t0)
                 sw $zero, 1092($t0)
                 sw $zero, 1224($t0)
                 sw $zero, 1208($t0) 
                 sw $zero, 1356($t0) 
                 sw $zero, 1332($t0)
                 
                 # draw gg 
                 sw $t6, 1964($t0)
                 sw $t6, 1968($t0)
                 sw $t6, 1972($t0)
                 sw $t6, 2088($t0)
                 sw $t6, 2216($t0)
                 sw $t6, 2344($t0)
                 sw $t6, 2472($t0)
                 sw $t6, 2604($t0)
                 sw $t6, 2608($t0)
                 sw $t6, 2612($t0)
                 sw $t6, 2488($t0)
                 sw $t6, 2360($t0)
                 sw $t6, 2356($t0)
                 sw $t6, 2364($t0)
                 sw $t6, 1992($t0)
                 sw $t6, 1996($t0)
                 sw $t6, 2000($t0)
                 sw $t6, 2116($t0)
                 sw $t6, 2244($t0)
                 sw $t6, 2372($t0)
                 sw $t6, 2500($t0)
                 sw $t6, 2632($t0)
                 sw $t6, 2636($t0)
                 sw $t6, 2640($t0)
                 sw $t6, 2516($t0)
                 sw $t6, 2388($t0)
                 sw $t6, 2384($t0)
                 sw $t6, 2392($t0)   
                                                   
                 jr $ra
                 
draw_ones_zero: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4088($t0) 
                sw $t6, 3960($t0) 
                sw $t6, 3832($t0)               
                sw $t6, 3704($t0)
                sw $t6, 3576($t0)             	 
                sw $t6, 3572($t0) 
                sw $t6, 3568($t0)
                sw $t6, 3696($t0)   
                sw $t6, 3824($t0) 
                sw $t6, 3952($t0)              
                sw $t6, 4080($t0)     
                sw $t6, 4084($t0)                 
                jr $ra

draw_ones_one: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4084($t0) 
               sw $t6, 3956($t0) 
               sw $t6, 3828($t0)               
               sw $t6, 3700($t0)
               sw $t6, 3572($t0)                  
               jr $ra

draw_ones_two: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4088($t0) 
               sw $t6, 3832($t0)
               sw $t6, 3828($t0)
               sw $t6, 3824($t0)               
               sw $t6, 3704($t0)
               sw $t6, 3576($t0)             	 
               sw $t6, 3572($t0) 
               sw $t6, 3568($t0)
               sw $t6, 3952($t0)              
               sw $t6, 4080($t0)     
               sw $t6, 4084($t0)                 
               jr $ra
               
draw_ones_three: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4088($t0) 
                 sw $t6, 3960($t0) 
                 sw $t6, 3832($t0)
                 sw $t6, 3828($t0)
                 sw $t6, 3824($t0)               
                 sw $t6, 3704($t0)
                 sw $t6, 3576($t0)             	 
                 sw $t6, 3572($t0) 
                 sw $t6, 3568($t0)          
                 sw $t6, 4080($t0)     
                 sw $t6, 4084($t0)                 
                 jr $ra               

draw_ones_four: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4088($t0) 
                sw $t6, 3960($t0) 
                sw $t6, 3832($t0)               
                sw $t6, 3704($t0)
                sw $t6, 3576($t0)             	  
                sw $t6, 3568($t0)
                sw $t6, 3696($t0)   
                sw $t6, 3824($t0) 
                sw $t6, 3828($t0)
                jr $ra

draw_ones_five: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4088($t0) 
                sw $t6, 3960($t0) 
                sw $t6, 3832($t0)
                sw $t6, 3828($t0)
                sw $t6, 3824($t0)               
                sw $t6, 3576($t0)             	 
                sw $t6, 3572($t0) 
                sw $t6, 3568($t0)
                sw $t6, 3696($t0)          
                sw $t6, 4080($t0)     
                sw $t6, 4084($t0)                 
                jr $ra               

draw_ones_six: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4088($t0) 
               sw $t6, 3960($t0) 
               sw $t6, 3832($t0)
               sw $t6, 3828($t0)
               sw $t6, 3824($t0)             
               sw $t6, 3576($t0)             	 
               sw $t6, 3572($t0) 
               sw $t6, 3568($t0)
               sw $t6, 3696($t0)
               sw $t6, 3952($t0)          
               sw $t6, 4080($t0)     
               sw $t6, 4084($t0)                 
               jr $ra    
                         
draw_ones_seven: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4088($t0) 
                 sw $t6, 3960($t0) 
                 sw $t6, 3832($t0)               
                 sw $t6, 3704($t0)
                 sw $t6, 3576($t0)             	 
                 sw $t6, 3572($t0) 
                 sw $t6, 3568($t0)             
                 jr $ra                              

draw_ones_eight: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4088($t0) 
                 sw $t6, 3960($t0) 
                 sw $t6, 3832($t0)
                 sw $t6, 3828($t0)
                 sw $t6, 3824($t0)        
                 sw $t6, 3704($t0)     
                 sw $t6, 3576($t0)             	 
                 sw $t6, 3572($t0) 
                 sw $t6, 3568($t0)
                 sw $t6, 3696($t0)
                 sw $t6, 3952($t0)          
                 sw $t6, 4080($t0)     
                 sw $t6, 4084($t0)                 
                 jr $ra    
 
draw_ones_nine: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4088($t0) 
                sw $t6, 3960($t0) 
                sw $t6, 3832($t0)
                sw $t6, 3828($t0)
                sw $t6, 3824($t0)        
                sw $t6, 3704($t0)     
                sw $t6, 3576($t0)             	 
                sw $t6, 3572($t0) 
                sw $t6, 3568($t0)
                sw $t6, 3696($t0)                         
                jr $ra   

draw_tens_zero: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4072($t0) 
                sw $t6, 3944($t0) 
                sw $t6, 3816($t0)               
                sw $t6, 3688($t0)
                sw $t6, 3560($t0)             	 
                sw $t6, 3556($t0) 
                sw $t6, 3552($t0)
                sw $t6, 3680($t0)   
                sw $t6, 3808($t0) 
                sw $t6, 3936($t0)              
                sw $t6, 4064($t0)     
                sw $t6, 4068($t0)                 
                jr $ra
                
draw_tens_one: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4068($t0) 
               sw $t6, 3940($t0) 
               sw $t6, 3812($t0)               
               sw $t6, 3684($t0)
               sw $t6, 3556($t0)                  
               jr $ra

draw_tens_two: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4072($t0) 
               sw $t6, 3816($t0)
               sw $t6, 3812($t0)
               sw $t6, 3808($t0)               
               sw $t6, 3688($t0)
               sw $t6, 3560($t0)             	 
               sw $t6, 3556($t0) 
               sw $t6, 3552($t0)
               sw $t6, 3936($t0)              
               sw $t6, 4064($t0)     
               sw $t6, 4068($t0)                 
               jr $ra
               
draw_tens_three: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4072($t0) 
                 sw $t6, 3944($t0) 
                 sw $t6, 3816($t0)
                 sw $t6, 3812($t0)
                 sw $t6, 3808($t0)               
                 sw $t6, 3688($t0)
                 sw $t6, 3560($t0)             	 
                 sw $t6, 3556($t0) 
                 sw $t6, 3552($t0)          
                 sw $t6, 4064($t0)     
                 sw $t6, 4068($t0)                 
                 jr $ra               

draw_tens_four: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4072($t0) 
                sw $t6, 3944($t0) 
                sw $t6, 3816($t0)               
                sw $t6, 3688($t0)
                sw $t6, 3560($t0)             	  
                sw $t6, 3552($t0)
                sw $t6, 3680($t0)   
                sw $t6, 3808($t0) 
                sw $t6, 3812($t0)
                jr $ra

draw_tens_five: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4072($t0) 
                sw $t6, 3944($t0) 
                sw $t6, 3816($t0)
                sw $t6, 3812($t0)
                sw $t6, 3808($t0)               
                sw $t6, 3560($t0)             	 
                sw $t6, 3556($t0) 
                sw $t6, 3552($t0)
                sw $t6, 3680($t0)          
                sw $t6, 4064($t0)     
                sw $t6, 4068($t0)                 
                jr $ra               

draw_tens_six: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
               sw $t6, 4072($t0) 
               sw $t6, 3944($t0) 
               sw $t6, 3816($t0)
               sw $t6, 3812($t0)
               sw $t6, 3808($t0)             
               sw $t6, 3560($t0)             	 
               sw $t6, 3556($t0) 
               sw $t6, 3552($t0)
               sw $t6, 3680($t0)
               sw $t6, 3936($t0)          
               sw $t6, 4064($t0)     
               sw $t6, 4068($t0)                 
               jr $ra    
                         
draw_tens_seven: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4072($t0) 
                 sw $t6, 3944($t0) 
                 sw $t6, 3816($t0)               
                 sw $t6, 3688($t0)
                 sw $t6, 3560($t0)             	 
                 sw $t6, 3556($t0) 
                 sw $t6, 3552($t0)             
                 jr $ra                              

draw_tens_eight: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                 sw $t6, 4072($t0) 
                 sw $t6, 3944($t0) 
                 sw $t6, 3816($t0)
                 sw $t6, 3812($t0)
                 sw $t6, 3808($t0)        
                 sw $t6, 3688($t0)     
                 sw $t6, 3560($t0)             	 
                 sw $t6, 3556($t0) 
                 sw $t6, 3552($t0)
                 sw $t6, 3680($t0)
                 sw $t6, 3936($t0)          
                 sw $t6, 4064($t0)     
                 sw $t6, 4068($t0)                 
                 jr $ra    
 
draw_tens_nine: addi $t6, $zero, 0x6F11B3 # colour for digits                 	 
                sw $t6, 4072($t0) 
                sw $t6, 3944($t0) 
                sw $t6, 3816($t0)
                sw $t6, 3812($t0)
                sw $t6, 3808($t0)        
                sw $t6, 3688($t0)     
                sw $t6, 3560($t0)             	 
                sw $t6, 3556($t0) 
                sw $t6, 3552($t0)
                sw $t6, 3680($t0)                         
                jr $ra 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
draw_sky: lw $t4, displayAddress  # initialize t4 which stores the address for the pixel of the background that we are currently drawing 
 next_sky: beq $t4, 268472320, sky_done #268472320 from display address plus 4096 (32 rows times 32 4 byte colours per row) 
           sw $t1, 0($t4) # draw this address' pixel deep sky blue
           addi $t4, $t4, 4 # update the address in t4 to the next pixel
           j next_sky
 sky_done: jr $ra
                                  	
draw_random_platform: li $v0, 42 # randomly generate the row of the platform
                       li $a0, 0
                       add $a1, $zero, $a2 # set how wide the range of the platforms is
                       syscall
                       sw $a0, platformStartRow # store the row into platformStartRow in memory
                       li $v0, 42 # randomly generate the starting column of the row
                       li $a0, 0
                       li $a1, 26 # 26 because platforms are 7 units wide
                       syscall 
                       sw $a0, platformStartColumn # store the column into platformStartColumn in memory  
                       lw $t6, rowMultiplier # load row mult so we can multiply by the row to get to the pixel location
                       lw $t7, columnMultiplier # load column mult so we can multipy by the column to get to the pixel location 
                       lw $t8, platformStartRow 
                       lw $t9, platformStartColumn 
                       add $t8, $t8, $a3 # add a3 rows to the generated row in order for the platform to be in the appropiate row range
                       mult $t6, $t8 # multiply the randomly generated row by the row multiplier 
                       mflo $t8 # move the row multiplied by the row multiplier into t8 
                       mult $t7, $t9 # multiply the randomly generated column by the column multiplier 
                       mflo $t7 # move the column multiplied by the column multiplier into t7 
                       add $t8, $t7, $t8 # add the final column and row result to get the platform starting pixel
                       add $t8, $t0, $t8 # add the platform starting pixel to the display address
                       sw $t3, 0($t8) # draw the platform
                       sw $t3, 4($t8) 
                       sw $t3, 8($t8)
                       sw $t3, 12($t8)
                       sw $t3, 16($t8)
                       sw $t3, 20($t8)
                       sw $t3, 24($t8)
                       jr $ra  
 
check_plat_collision: addi $t6, $zero, 28 # store offset for doodler left foot  
                      lw $t7, doodlerArray($t6) # load doodler left foot address into t7
                      lw $t6, deathRow 
                      bge $t7, $t6, Exit # checks if doodler left foot is at bottom row of screen, if so terminate the program   
                      addi $t8,  $t7, 128 # put address of unit below doodler left foot into t8 
                      lw $t6, 0($t8) # load colour stored at unit below doodler left foot 
                      bne $t6, $t3, no_left_plat_collision # if unit below doodler left foot is not a platform, jump to no left collision
                 
                      # code if doodler hits a platform with its left foot
                      lw $t7, jumpTime
                      bgt $t7, $zero, no_plat_collision # dont count the collision if doodler still has jump time left 
                      addi $t6, $zero, 15 # put newly reset jump time into t6 
                      sw $t6, jumpTime # reset jumpTime to 15 
                      lw $t6, score
                      addi $t6, $t6, 1
                      sw $t6, score
                      jr $ra # jump to return address if already collided 
                 
                   #repeat above instructions for doodler right foot     
no_left_plat_collision: addi $t6, $zero, 32 
                        lw $t7, doodlerArray($t6)
                        addi $t8, $t7, 128  
                        lw $t6, 0($t8)
                        bne $t6, $t3, no_plat_collision
                   
                        # code for if doodler hits a platform with its right foot
                        lw $t7, jumpTime
                        bgt $t7, $zero, no_plat_collision  # dont count the collision if doodler still has jump time left
                        addi $t6, $zero, 15
                        sw $t6, jumpTime
                        lw $t6, score
                        addi $t6, $t6, 1
                        sw $t6, score
                        jr $ra # already collided so return  
     
no_plat_collision: lw $t6, jumpTime # decrease jump time by one, this is intended if the doodler was jumping up and didn't collide with a platform
                   sub $t6, $t6, 1 # if doodler is moving down, the code will still be fine because jumpTime should be at most 0 right now
                   sw $t6, jumpTime # and the next time it collides with a platform it will reset to 8 with no problems
                   jr $ra # no collision detected, return  
                   
                      # check for collision with the right and left wall, wrap around 
                      # as soon as one body part is determined to have collided, can move all column aligned body parts with it and save time 
                      # collision currently bugged, when only doodler left body is wrapped on left side, platform drops a level sometimes
                      # also, wrapping occasionally works incorrectly, mainly happens when going back and forth between the boundary
check_wall_collision:                      
check_left_wall_collision:  bne $a0, -12, check_right_wall_collision
                            addi $a3, $zero, 128
                            addi $t6, $zero, 0 # index for the doodler array
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            lw $t8, rowMultiplier
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 124, wrap_left_head # check if body part is at the last column
                            beq $t7, 120, wrap_left_head # check if body part is at the second last column
                            beq $t7, 116, wrap_left_head # check if body part is at the third last column 
        Lcheck_middle_head: addi $t6, $t6, 4 # move to next column of body parts and repeat
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 124, wrap_middle_head
                            beq $t7, 120, wrap_middle_head 
                            beq $t7, 116, wrap_middle_head 
         Lcheck_right_head: addi $t6, $t6, 4 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 124, wrap_right_head
                            beq $t7, 120, wrap_right_head 
                            beq $t7, 116, wrap_right_head 
         Lcheck_right_body: addi $t6, $t6, 8 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 124, wrap_right_body
                            beq $t7, 120, wrap_right_body
                            beq $t7, 116, wrap_right_body 
          Lcheck_left_body: addi $t6, $t6, -4 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 124, wrap_left_body
                            beq $t7, 120, wrap_left_body
                            beq $t7, 116, wrap_left_body 
                            jr $ra 
check_right_wall_collision: bne $a0, 12, no_wall_collision
                            addi $a3, $zero, -128
                            addi $t6, $zero, 0 # index for the doodler array
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            lw $t8, rowMultiplier
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 0, wrap_left_head # check if body part is at the first column
                            beq $t7, 4, wrap_left_head # check if body part is at the second column
                            beq $t7, 8, wrap_left_head # check if body part is at the third column
        Rcheck_middle_head: addi $t6, $t6, 4 # move to next column of body parts and repeat
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 0, wrap_middle_head
                            beq $t7, 4, wrap_middle_head
                            beq $t7, 8, wrap_middle_head
        Rcheck_right_head:  addi $t6, $t6, 4 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 0, wrap_right_head
                            beq $t7, 4, wrap_right_head
                            beq $t7, 8, wrap_right_head
         Rcheck_right_body: addi $t6, $t6, 8 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 0, wrap_right_body
                            beq $t7, 4, wrap_right_body
                            beq $t7, 8, wrap_right_body
          Rcheck_left_body: addi $t6, $t6, -4 # move to next column of body parts
                            lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                            div $t7, $t8
                            mfhi $t7 
                            beq $t7, 0, wrap_left_body
                            beq $t7, 4, wrap_left_body
                            beq $t7, 8, wrap_left_body
         no_wall_collision: jr $ra                       
            wrap_left_head: addi $t5, $zero, 0 # index into left head
                            lw $t7, doodlerArray($t5) # load doodler body part address into t7 
                            add $t7, $t7, $a3 # move body part up or down one row depEnding on argument
                            sw $t7, doodlerArray($t5) # store updated body part
                            addi $t5, $t5, 28 # index into left foot and repeat          
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3 
                            sw $t7, doodlerArray($t5)
                            #keep checking, can collide more than one column of body parts since horizontal movement is 3 units
                            beq $a0, -12, Lcheck_middle_head
                            beq $a0, 12, Rcheck_middle_head
          wrap_middle_head: addi $t5, $zero, 4 # index into middle head
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3  
                            sw $t7, doodlerArray($t5) 
                            beq $a0, -12, Lcheck_right_head
                            beq $a0, 12, Rcheck_right_head
           wrap_right_head: addi $t5, $zero, 8 # index into right head
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3  
                            sw $t7, doodlerArray($t5) 
                            addi $t5, $t5, 24 # index into right foot and repeat          
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3 
                            sw $t7, doodlerArray($t5)
                            beq $a0, -12, Lcheck_right_head
                            beq $a0, 12, Rcheck_right_body
           wrap_right_body: addi $t5, $zero, 16 # index into right upper body
                            lw $t7, doodlerArray($t5)
                            add $t7, $t7, $a3  
                            sw $t7, doodlerArray($t5)
                            addi $t5, $t5, 8 # index into right lower body and repeat          
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3 
                            sw $t7, doodlerArray($t5)               
                            beq $a0, -12, Lcheck_left_body
                            beq $a0, 12, Rcheck_left_body              
            wrap_left_body: addi $t5, $zero, 12 # index into left upper body
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3  
                            sw $t7, doodlerArray($t5) 
                            addi $t5, $t5, 8 # index into left lower body and repeat          
                            lw $t7, doodlerArray($t5) 
                            add $t7, $t7, $a3 
                            sw $t7, doodlerArray($t5)
                            jr $ra
	                      
update_platform_check: addi $t6, $zero, 28
                       lw $t7, doodlerArray($t6) # check if the doodler's foot is at the middle of the screen
                       lw $t6, halfScreen
                       ble $t7, $t6, update_platforms
                       jr $ra   
                       
     update_platforms: # keep the doodler at the middle of the screen
                       addi $t6, $zero, 0 # index for the doodler array
                       lw $t7, doodlerArray($t6) # load doodler body part address into t7 
                       addi $t7, $t7, 128 # move doodler body part down one
                       sw $t7, doodlerArray($t6) # store updated doodler body part location
                       addi $t6, $t6, 4 # move to next body part of the doodler and repeat
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       lw $t7, doodlerArray($t6)
                       addi $t7, $t7, 128 
                       sw $t7, doodlerArray($t6)
                       addi $t6, $t6, 4
                       
                       # move each platform down one row and draw over the old platform locations  
                       lw $t6, platformOne
                       addi $t6, $t6, 128 # temporarily add 1 row to the platform to see if it would be 6 rows away from the top
                       addi $t8, $zero, 8
                       lw $t7, rowMultiplier
                       mult $t8, $t7 
                       mflo $t8
                       lw $t7, displayAddress
                       add $t8, $t8, $t7
                       bge $t6, $t8, new_platform # check if top platform is 8 rows away from the first row, if so spawn new platform
                       addi $t6, $t6, -128 # remove the temporarily added row because we are actually adding the row soon  
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       sw $t6, platformOne
                       lw $t6, platformTwo
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       sw $t6, platformTwo
                       lw $t6, platformThree
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       sw $t6, platformThree
                       lw $t6, platformFour
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       sw $t6, platformFour
                       jr $ra
                       
         new_platform: # move the previous first four platform locations down and store them again as the current last four platforms
                       lw $t6, platformOne
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       lw $t7, platformTwo # tactic here is saving the old platform two vlaue in t7
                       sw $t6, platformTwo # and then storing the new platform two value in platformTwo
                       sw $t1, 0($t7)
                       sw $t1, 4($t7)
                       sw $t1, 8($t7)
                       sw $t1, 12($t7)
                       sw $t1, 16($t7)
                       sw $t1, 20($t7)
                       sw $t1, 24($t7)
                       addi $t7, $t7, 128
                       lw $t6, platformThree
                       sw $t7, platformThree
                       sw $t1, 0($t6)
                       sw $t1, 4($t6)
                       sw $t1, 8($t6)
                       sw $t1, 12($t6)
                       sw $t1, 16($t6)
                       sw $t1, 20($t6)
                       sw $t1, 24($t6)
                       addi $t6, $t6, 128
                       lw $t7, platformFour
                       sw $t6 platformFour
                       # delete the former platform four
                       sw $t1, 0($t7)
                       sw $t1, 4($t7)
                       sw $t1, 8($t7)
                       sw $t1, 12($t7)
                       sw $t1, 16($t7)
                       sw $t1, 20($t7)
                       sw $t1, 24($t7)
                       # store a new randomly generated platform in the top row as platform one
                       li $v0, 42 # randomly generate the starting column of the row
                       li $a0, 0
                       li $a1, 26 # 26 because platforms are 7 units wide
                       syscall 
                       lw $t7, columnMultiplier # load column mult so we can multipy by the column to get to the pixel location 
                       mult $t7, $a0 # multiply the randomly generated column by the column multiplier 
                       mflo $t7 # move the column multiplied by the column multiplier into t7 
                       add $t7, $t7, $t0 # add the display address to t7 to get the final pixel address on screen
                       sw $t7, platformOne
                       jr $ra
                       
platforms_check:          lw $t4, displayAddress # reload t4 with the display address          
      platform_one_check: add $t6, $zero, $t4  # load the current pixel address into t6
                          lw $t6, 0($t6) # load the colour stored at the current pixel address into t6
                          beq $t3, $t6, store_platform_one # check if this pixel stores the start of the first platform
                          addi $t4, $t4, 4 # update the address in t4 to the next pixel
                          j platform_one_check
      store_platform_one: sw $t4, platformOne # store the address of the starting pixel of the first platform in platformOne
                          addi $t4, $t4, 28 # skip the next 6 pixels because they belong to the first platform
                          
                          #repeat for the other three platform locations            
      platform_two_check: add $t6, $zero, $t4 
                          lw $t6, 0($t6) 
                          beq $t3, $t6, store_platform_two
                          addi $t4, $t4, 4
                          j platform_two_check
      store_platform_two: sw $t4, platformTwo
                          addi $t4, $t4, 28
    platform_three_check: add $t6, $zero, $t4 
                          lw $t6, 0($t6) 
                          beq $t3, $t6, store_platform_three
                          addi $t4, $t4, 4 
                          j platform_three_check
    store_platform_three: sw $t4, platformThree 
                          addi $t4, $t4, 28
     platform_four_check: add $t6, $zero, $t4 
                          lw $t6, 0($t6) 
                          beq $t3, $t6, store_platform_four
                          addi $t4, $t4, 4 
                          j platform_four_check
     store_platform_four: sw $t4, platformFour 
                          addi $t4, $t4, 28
                          jr $ra
		                       
redraw_screen: addi $sp, $sp, -4
               sw $ra, 0($sp) 
               addi $t7, $zero, 0 # store the index of the doodler array in t7
               lw $t6, doodlerArray($t7) # load the current left head address of the doodler into t6
               sw $t2, 0($t6) # draw the doodler left foot 
               addi $t7, $t7, 4 # move to the next body part of the doodler in the doodler array and repeat the process
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               addi $t7, $t7, 4
               lw $t6, doodlerArray($t7)
               sw $t2, 0($t6)
               # draw all the platforms
               lw $t6, platformOne
               sw $t3, 0($t6)
               sw $t3, 4($t6)
               sw $t3, 8($t6)
               sw $t3, 12($t6)
               sw $t3, 16($t6)
               sw $t3, 20($t6)
               sw $t3, 24($t6)
               lw $t6, platformTwo
               sw $t3, 0($t6)
               sw $t3, 4($t6)
               sw $t3, 8($t6)
               sw $t3, 12($t6)
               sw $t3, 16($t6)
               sw $t3, 20($t6)
               sw $t3, 24($t6)
               lw $t6, platformThree
               sw $t3, 0($t6)
               sw $t3, 4($t6)
               sw $t3, 8($t6)
               sw $t3, 12($t6)
               sw $t3, 16($t6)
               sw $t3, 20($t6)
               sw $t3, 24($t6)
               lw $t6, platformFour
               sw $t3, 0($t6)
               sw $t3, 4($t6)
               sw $t3, 8($t6)
               sw $t3, 12($t6)
               sw $t3, 16($t6)
               sw $t3, 20($t6)
               sw $t3, 24($t6)
               lw $ra, 0($sp)
               addi $sp, $sp, 4
               jr $ra

Exit:          jal draw_end_screen # draw game over screen
               lw $t6, score # load score
               addi $t7, $zero, 10
               div $t6, $t7 # divide score by 10, quotient is tens digit, remainder is ones digit
               mflo $t6 # store tens digit 
               mfhi $t7 # store ones digit
               
               #determine which tens digit to draw
               beq $t6, 0, zero_tens_score
               beq $t6, 1, one_tens_score
               beq $t6, 2, two_tens_score
               beq $t6, 3, three_tens_score
               beq $t6, 4, four_tens_score
               beq $t6, 5, five_tens_score
               beq $t6, 6, six_tens_score
               beq $t6, 7, seven_tens_score
               beq $t6, 8, eight_tens_score
               beq $t6, 9, nine_tens_score
               j Ending # if score exceeds limit, skip score display
               
check_ones_score: #determine which ones digit to draw
                  beq $t7, 0, zero_ones_score
                  beq $t7, 1, one_ones_score
                  beq $t7, 2, two_ones_score
                  beq $t7, 3, three_ones_score
                  beq $t7, 4, four_ones_score
                  beq $t7, 5, five_ones_score
                  beq $t7, 6, six_ones_score
                  beq $t7, 7, seven_ones_score
                  beq $t7, 8, eight_ones_score
                  beq $t7, 9, nine_ones_score
               
zero_tens_score:  jal draw_tens_zero
                  j check_ones_score       
one_tens_score:   jal draw_tens_one
                  j check_ones_score
two_tens_score:   jal draw_tens_two
                  j check_ones_score
three_tens_score: jal draw_tens_three
                  j check_ones_score
four_tens_score:  jal draw_tens_four
                  j check_ones_score
five_tens_score:  jal draw_tens_five
                  j check_ones_score
six_tens_score:   jal draw_tens_six
                  j check_ones_score
seven_tens_score: jal draw_tens_seven
                  j check_ones_score
eight_tens_score: jal draw_tens_eight
                  j check_ones_score
nine_tens_score:  jal draw_tens_nine
                  j check_ones_score
               
zero_ones_score:  jal draw_ones_zero
                  j Ending       
one_ones_score:   jal draw_ones_one
                  j Ending
two_ones_score:   jal draw_ones_two
                  j Ending
three_ones_score: jal draw_ones_three
                  j Ending
four_ones_score:  jal draw_ones_four
                  j Ending
five_ones_score:  jal draw_ones_five
                  j Ending
six_ones_score:   jal draw_ones_six
                  j Ending
seven_ones_score: jal draw_ones_seven
                  j Ending
eight_ones_score: jal draw_ones_eight
                  j Ending
nine_ones_score:  jal draw_ones_nine
                  j Ending

                                                     
Ending:        lw $t8, 0xffff0000 # load whether the key was pressed, 1 if pressed, 0 if no
               beq $t8, 1, restart_check # if a key was pressed check if it was the start button
               j Ending # if no key pressed, keep waiting for key press
restart_check: lw $t7, 0xffff0004 # load the ascii code of the pressed key if any        
               beq $t7, 115, restart # restart game if restart key is pressed
               j Ending # keep waiting until user presses restart key or closes program

li $v0, 10 # terminate the program gracefully
syscall
