;
;       Slowdos Source Code
;
;
;       $Id: poke.asm,v 1.1 2003/06/15 20:26:26 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:26 $
;
;       The POKE @ command 


		MODULE	poke

		INCLUDE	"syntax.def"


		XDEF	poke
	
	
;
; Poke@ command. Supported syntax:
;
; POKE @a1,d1
;
; If d1 < 256 then 8 bit poke, otherwise 16 bit poke
;
         
poke:     call  rout32  
          cp    '@'  		; Check for '@'
          jp    nz,error_nonsense  	; No? Call Nonsense in BASIC
          call  e32_1n  	; We expect one number
          cp    ','  		; Then a comma
          jp    nz,error_nonsense  	; No comma, Nonsense in BASIC
          call  e32_1n  	; We now want another number
          call  ckend  		; And end of statement
          call  getnum		; Get the value from the stack
          push  bc  		; Store it
          call  getnum		; Get the address
          ld    h,b  		; Get it into hl
          ld    l,c  
          pop   bc  		; Now get the value back
          ld    (hl),c  	; And poke it
          inc   hl  		; Increment the address
          ld    a,b  		; Check if the high byte of the value != 0
          and   a  
          ret   z		; It is zero then return
          ld    (hl),b  	; Else poke it
	  ret			; Command finished
