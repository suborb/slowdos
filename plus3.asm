;
;	Slowdos Source Code
;
;
;	$Id: plus3.asm,v 1.1 2003/06/15 20:26:26 dom Exp $
;	$Author: dom $
;	$Date: 2003/06/15 20:26:26 $
;
;	Provides some low level +3 routines



		MODULE		plus3
		INCLUDE		"slowdos.def"

		XREF		errorn

		XDEF		sros
		XDEF		sros1
		XDEF		ros

		XDEF		swos
		XDEF		swos1
		XDEF		wos

		XDEF		dodos
		XDEF		dcheat
		XDEF		cjump
		XDEF		xdpb

	
;
; Sector Read/writing routines
;

sros:     ld    hl,sector       ; Address to read to
sros1:    ld    b,syspag  	; What memory page system is contained in
          jr    ros0  

ros:      ld    a,(page)	; Page to read to
          and   7  		; Make sure its in range
          ld    b,a  
ros0:     ld    iy,355		; +3DOS read sector vector
          jr    wos3
       
; Write a sector to disc
swos:     ld    hl,wrisec   	; Write a sector from system space
swos1:    ld    b,syspag  
          jr    wos0  

wos:      ld    a,(page)	; Write a sector from user space
          and   7  
          ld    b,a
wos0:     ld    iy,358		; +3DOS write sector vector

wos3:     ld    c,1		; Unit 1 (drive B:)
          call  calsec		; Returns +3 track+sector from DOS track/sector
wos1:     ld    (wos2+2),ix  
          ld    ix,xdpb  
          call  dodos  
wos2:     ld    ix,0  
          ret   

;Calculate +3 track + sector
;from MSDOS sector number
;Entry: de=MSDOS sector
;Exit    d=logical track
;        e=sector number
          
calsec:   push  hl  		; Save hl + bc so we don't contaminate
          push  bc  
          ex    de,hl  		; Get DOS sector into hl
          ld    d,255  		; Start off with an impossible track
          ld    bc,9		; FIXME Sectors per track 
calse1:   inc   d  		; Increment track
          and   a  		; Clear carry so subtraction works
          sbc   hl,bc  
          jr    nc,calse1  	; Loop on round whilst hl > 0
          add   hl,bc  		; We went -ve restore
          ld    e,l  		; So l = 0 - 9, which is the sector within track
          pop   bc  		; Restore those registers that we used
          pop   hl  
          ret   

        


          
; +3 DOS call routine
; Directly from the manual (as usual)
dodos:    di    
          push  af  
          push  bc  
          ld    a,7  
          ld    bc,32765  
          out   (c),a  
          ld    (23388),a  
          pop   bc  
          pop   af  
          ei    
          call  cjump  
          di    
          push  af  
          push  bc  
          ld    bc,32765  
          ld    a,23  
          out   (c),a  
          ld    (23388),a  
          pop   bc  
          pop   af  
          ld    iy,23610  
          ei    
dcheat:   ret   c  
	;;  Convert +3DOS errors to rst 8 errors
errou:
errou2:	  ld    b,24
	  cp	10
	  jr	nc,higherrors
	  add   61
higherrors:	
	  add   b
	  ld    (errou1),a
	  call  errorn
errou1:   defb  0
	  
          
cjump:    jp    (iy)
          


;;  Disc specification
xdpb:     defb    36,0,4,15,0,100,1
          defb    127,0,192,0,32,0,1,0
          defb    2,3,129,80,9,1,0,2
          defb    42,82,96,0