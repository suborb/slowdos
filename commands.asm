;
;       Slowdos Source Code
;
;
;       $Id: commands.asm,v 1.1 2003/06/14 23:08:18 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/14 23:08:18 $
;
;	Main entry point for Slowdos



;New start up file for SLOWDOS
;Hacked from DiSCDOS file hook1.asm
;Removed all the hook code crap
;14/2/98 - adding in a few commands
;18/2/98 - modifying r_wropen to consider headerless
;19/2/98 - commenting out command stuff
;20/2/98 - sorting out old discdos hook code stuff...
;23/2/98 - inserting in systen calls (note new name!!!)
;27/3/98 - new version number 2.31

;hkspst:   equ   23411  
;hkhlst:   equ   23728  
          
;Need to change this equs
;wrisec:   equ   63968  
;sector:   equ   46080  ;64960  

;ROM3 equs 
getin1:   equ   11249  
fnint1:   equ   1E94h  
fnint2:   equ   1E99h  
          
          jp    init  		; This is address 49152
          jp    hkent		; This is address 49155
          
; Copy our structures over to the printer buffer area. We intercept
; the various error routines that pass between the ROMS

init:     ld    hl,errpat  
          ld    de,23354  
          ld    bc,24  
          ldir  
          ld    a,201  		;ret
          ld    (dcheat),a  	;Nobble the dodos return so we don't get an err
          xor   a  
          ld    iy,334  	;??? vector
          call  dodos  
          ld    a,216  		;ret c
          ld    (dcheat),a  
          ret

;
; Code that is copied down to the printer buffer area
;
 

errpat:   di    		;1
          ex    af,af'  	;1
          exx   		;1
          ld    hl,23354  	;3
          push  hl  		;1
          ld    a,23  		;2
          ld    bc,32765  	;3
          out   (c),a  		;1
          jp    intro  		;3
          out   (c),e    	;1 - +17  
          exx   		;1
          ei    		;1
SFAIL0:	  jp	9530
          
page:     db    0  
hksthl:   dw    0  
          
          db    'SLOWDOS v2.4 '
          db    '(C) 24.02.2001 D.J.'
          db    'MORRIS'

intro:    ld    hl,23388  
          ld    b,(hl)  
          ld    (hl),a  
          ld    a,b  
          ld    (page),a  
          ld    (spstor),sp  
          ld    sp,(23402)  
          ld    hl,flags  
          res   0,(hl)  
          ei    
          call  scan  
intro0:   ld    (23354+22),hl  
intro1:   di    
          xor   a  
          ld    (23390),a  
          ld    a,0  
          ld    bc,8189  
          out   (c),a  
          ld    (23399),a  
          set   4,a  
          ld    bc,32765  
          ld    (23388),a  
          ld    e,a  
          ld    sp,(spstor)  
          ld    hl,flags  
          bit   0,(hl)  
          jr    z,intro2  
          pop   hl  
intro2:   jp    23354+17  
          
          
;ROM 3 caller..
rom3:     exx   
          ex    af,af'  
          ld    hl,routca  
          ld    de,23420  
          ld    bc,25  
          ldir  
          ld    hl,flags  
          set   7,(hl)  
          pop   hl  
          ld    a,(hl)  
          inc   hl  
          inc   hl  
          ld    (retadd+1),hl  
          dec   hl  
          ld    h,(hl)  
          ld    l,a  
          ld    (23420+6),hl  
          di    
          ld    bc,32765  
          ld    a,16  
          ld    (23388),a  
          ld    (dossp),sp  
          ld    sp,(spstor)  
          jp    23420
routi1:   ld    sp,(dossp)  
          ld    (23388),a  
retadd:   ld    hl,0  
          push  hl  
          ld    hl,flags  
          res   7,(hl)  
          ex    af,af'  
          exx   
          ei    
          ret   
          
dossp:    dw    23552  
          
routca:   out   (c),a  
          ex    af,af'  
          exx   
          ei    
          call  0  
routc1:   di    
          exx   
          ex    af,af'  
          ld    a,23  
          ld    bc,32765  
          out   (c),a  
          jp    routi1  

;
; Entry point for hook codes
;

hkent:    ld   (hkent+1),sp	; save the current stack
          push hl
          exx
          ld   hl,flags3
          set  5,(hl)
          ld   hl,hkext0
          ex   (sp),hl
          ld   a,h
          ld   (page),a
          ld   a,l
          cp   15
          jr   nc,hkext
          ld   h,0
;          pop  hl
          add  hl,hl
          ld   de,hktabl
          add  hl,de
          ld   e,(hl)
          inc  hl
          ld   d,(hl)
          push de
;          ld   hl,10072
          exx
          ret
hkext0:   scf
hkext:    ld   hl,flags3
          res  5,(hl)
          res  7,(hl)
          ld   (iy+0),255
hkent1:   ld   sp,0
          ret

          


hktabl:   dw   mslog
          dw   r_getpar
          dw   r_rdopen
          dw   rdbyte
          dw   rdblok  ;de=addr, bc=length
          dw   r_wropen
          dw   wrbyte
          dw   wrblok
          dw   wrclos
          dw   r_erase
          dw   snpcnt
          dw   r_mscat
          dw   r_catmem
          dw   movsdie  ;de=start of text, bc=length
;          dw   r_tread
;ix=ufia
r_rdopen: call r_hxfer
          jp   rdopen
r_wropen: call r_hxfer
;Have to check for long filetype
;long filettpe indicates headerless file
          ld   hl,(ufia+16)
          ld   (wrflen),hl
          ld   hl,0
          ld   (wrflen+2),hl
          ld   hl,flags
          res  5,(hl)
          ld   a,(ufia+15)
          cp   5
          jr   nz,r_wrope1
          set  5,(hl)
r_wrope1: jp   wropen
r_erase:  call r_hxfer
          call uftofin
          ld   hl,filen
          call ckwild
          jp   en_ers
r_catmem: ex   de,hl
          ld   (dumadd2+1),hl
          inc  hl
          ld   (dumadd+1),hl
          ld   hl,flags3
          set  7,(hl)
r_mscat:  call r_hxfer
          call uftofin
          jp   ncats3
;r_tread:  call r_hxfer
;          jp   tread2
r_getpar: ld   de,temphd
          ret
r_hxfer:  push ix
          pop  hl
          ld   de,ufia
          push de
          ld   bc,22
          ldir
          pop  ix
          ret





          
scan:     ld    hl,flags  
          bit   7,(hl)  
          jr    nz,scan0  
          ld    a,(iy+0)  
          cp    11  
          jp    z,write  
          cp    1  
          jp    z,write  
scan0:    ld    hl,flags  
          res   7,(hl)  
          set   0,(hl)  
SFAIL1	ld	hl,9530
	ret

          
;Error return - also for non recognized command
;Check to see if executing system call
scan1:    ld   hl,flags3
          and  a
          bit  5,(hl)
          jp   nz,hkext
          call  syntax
          jr    nz,scan12  
          ld    hl,(23645)  
          ld    (23647),hl  
scan12:   ld    hl,flags  
          set   0,(hl)  
SFAIL2	ld	hl,9530
	jp	intro0
          
;Exit when running program
runexe:	ld	hl,4145
	ret

;Syntax exit
synexe:	ld	hl,4280

;this pop needed to dump the return to runexe
          pop   bc  
          ret   
          
;Main syntax loop
write:    set   7,(iy+48)  
          bit   7,(iy+1)  
          jr    nz,writ01  
          res   7,(iy+48)  
writ01:   ld    hl,(23645)  
write0:   dec   hl  
          call  gfropg
          cp    206  
          jr    c,write0  
          ld    (23645),hl  
          call  rout24  
          ld    hl,runexe  
          push  hl  
          cp    207  
          jp    z,cat  
          cp    208  
          jp    z,format  
          cp    209  
          jp    z,move  
          cp    210  
          jp    z,erase  
          cp    213  
          jp    z,merge  
          cp    214  
          jp    z,verify  
          cp    239  
          jp    z,load  
          cp    244  
          jp    z,poke  
          cp    248  
          jp    z,save  
          cp    255  
          jp    z,copy  
          pop   hl  
          jp    scan1  
