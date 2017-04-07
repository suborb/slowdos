;
;       Slowdos Source Code
;
;
;       $Id: print.asm,v 1.1 2003/06/15 20:26:26 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:26 $
;
;       Routines regarding printing



		MODULE	printing


		EXTERN	cjump	; jp(hl)
		EXTERN	rom3

		PUBLIC	prhund
		PUBLIC	print
		PUBLIC	messag
		PUBLIC	string
		PUBLIC	setchan	
	

; Print a number out
; Entry:	hl = number
;		 b = 0, print leading zeros
;		 b = 255, print leading spaces
;		 b = 254, don't print anything
          
prhund:   ld    de,100  
          call  numcal  
          ld    de,10  
          call  numcal  
          ld    de,1  
          ld    b,0  	; Got to print something!
numcal:   ld    a,255  
numca1:   inc   a  
          and   a  
          sbc   hl,de  
          jr    nc,numca1  
          add   hl,de  
          and   a  
          jr    z,numca2  
          ld    b,0  
numca2:   add	A,48  
          ld    c,a  
          ld    a,b  
          and   a  
          jr    z,numca3  
          inc   a  
          ret   nz  
          ld    c,32  
numca3:   ld    a,c  
	;; Fall into print
	
print:    call  rom3  
          defw  16  
          ret   

; Print a string to screen.
; String to print is after the call to messag
          
messag:   pop   hl  
messa1:   ld    a,(hl)  
          inc   hl  
          cp    255  
          jp    z,cjump+1  
          call  print  
          jr    messa1  
          
; Print a string to screen
; Entry:	de = text
;		bc = length
string:   ld    a,b  
          or    c  
          ret   z  
          ld    a,(de)  
          call  print  
          inc   de  
          dec   bc  
          jr    string

	
setchan:  call  rom3
          defw  5633
          ret