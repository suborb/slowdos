;
;	Slowdos Source Code
;
;
;	$Id: standard.asm,v 1.1 2003/06/14 23:08:19 dom Exp $
;	$Author: dom $
;	$Date: 2003/06/14 23:08:19 $
;
;	Provides utility routines for all parts





;Get a string from the BASIC area
;used for filenames....
;Entry: hl=address to dump string...
;This has been sorted to handle null names
;if handling .TAP files..
;Further sorted out to not sort out filenames...

;
; Get a string from the BASIC memory area, used for filenames.
;
; Entry:	hl = address to dump string
; Entry(getst0) bc = how long the name should be
;
; NB. This function really is black magic!
                  
getstr:   ld    bc,12  		;8 + 3 + '.'
getst0:   push  hl  
          push  bc  
          ld    hl,gtfisp	;Just a temporary workspace
          ld    b,c
          call  clfil0		;Initialises b bytes at hl with ' '
          call  rom3  
          dw    11249  
          call  wrinit  	;
          pop   hl  
          and   a  
          sbc   hl,bc  
          jp    c,bfnerr  
;          pop   hl  
;Some temporary workspace
          ld    hl,gtfisp
          ld    b,c  
          ld    a,b  
          and   a  
          jr    nz,gets15  
;We have a null length filename...
          ld   hl,flags2
          bit  6,(hl)    ;not dealing with TAP at first glance
          jr   z,getsl4
          ld   a,(flags3) ;check whether this is real or not...
          bit  0,a
          jr   z,getsl4 ;it's not..we're reading from, but this ain't
;Okay, handling TAP file, so set filename up to be *
          set  1,(hl)    ;wild name
          pop  hl
          ld   a,'*'
          ld   (hl),a
          and  a ;set nz, (nc=not significent)
          ret
getsl4:   call  errorn  
          db    43  ;bad filename - ie none!!
gets15:
;gets15:   ld    (getst5),a  
;          push  bc  
          push  hl  
getst1:   push  hl  
          call  wrcopy  
          pop   hl  
          ld    (hl),a  
          inc   hl  
          inc   de  
          djnz  getst1  
          pop  hl ; hl=gtfisp
          pop  de  ;de=destination filename storage
          ld   a,(flags2)
          bit  6,a
          jr   nz,getstt
          bit  7,a
          call nz,getst9
          push de
          call plafil
getst8:   pop  hl
          push hl
          call  ckwild
          ld   hl,flags
getst4:   bit  1,(hl)  
          pop  hl  
          ret   
;This bit to handle .TAP names
getstt:   push de
          ld   bc,10
          ldir
          jr   getst8

;Get string sort out for +3 filenames
;hl=basic filename
;de=dest address
getst9:   push de
          push hl
          ex   de,hl
          ld   b,16
          call gp3dr0
          ld   hl,flags2
          res  7,(hl)
          ld   hl,(gp3dr4)
          pop  de
          and  a
          sbc  hl,de
          ld   b,h
          ld   c,l
          pop  hl
          ex   de,hl
          ld   a,b
          or   c
          ret  z
          ldir
          ret


;Plafil: designed to pad the filename fully
;out
;Entry:    hl=filename as from BASIC
;          de=addr of where to place filename

plafil:   push de
          ex   de,hl
          ld   b,12
          call clfil0
;ATP de=filename store got from BASIC
          ex   de,hl
          pop  de
;Entry: de=destination filename, hl=from BASIC
plafi0:   push de
          ld   b,8
          call plafi1
          ex   de,hl
          pop  hl
          ld   bc,8
          add  hl,bc
          ld   (hl),'.'
          inc  hl
          ex   de,hl
          ld   b,3
;The actual routine itself
plafi1:   ld   a,(hl)
          inc  hl
          cp   '.'
          ret  z
          ld   (de),a
          inc  de
          djnz plafi1
          inc  hl
          ret


;Check the filename and convert to upper
;case
;Entry:   hl=address of filename
;Exit:     c=filename bad
;         nc=filename good

ckchar:   ex   de,hl
          ld   b,8
          call ckcha1
          ret  c
          inc  de
          ld   b,3
          call ckcha1
          ret

ckcha1:   ld   a,(de)
          cp   97
          jr   c,ckcha2
          cp   123
          jr   nc,ckcha2
	  add	A,224
ckcha2:   ld   (de),a
          inc  de
          cp   127
          ccf
          ret  c
          cp   32
          ret  c
          ld   hl,badcha
ckcha3:   cp   (hl)
          scf
          ret  z
          inc  hl
          bit  7,(hl)
          jr   z,ckcha3
          djnz ckcha1
          and  a    
          ret



badcha:   db   '!&()+,-./:;<=>[\]|'
          db   128
          

;Rewritten to handle the MSDOS filename
;Entry:   hl=addy of filename

ckwild:   ld    b,12  
ckwil0:   push  hl  
          ld    hl,flags  
          res   1,(hl)  
          pop   hl  
ckwil1:   ld    a,(hl)  
          cp    '*'  
          jr    z,getst2  
          cp    '?'  
          jr    z,getst2  
getst3:   inc   hl  
          djnz  ckwil1  
          ret   
getst2:   push  hl  
          ld    hl,flags  
          set   1,(hl)  
          pop   hl  
          jr    getst3  
          

gtfisp:   ds    16,32
fildes:   ds    12,32  

;Clear the filename
;Entry:    hl=filename

clufia:   ld   hl,ufia+2
          jr   clfiln
clfilen:  ld   hl,filen
clfiln:   ld   b,12
clfil0:   push hl
clfil1:   ld   (hl),32
          inc  hl
          djnz clfil1
          pop  hl
          ret


;Copy the filename in the UFIA to filen
;Entry:   ix=ufia
;Exit:    ix=ufia
;         hl=ufia+2

uftofin:  push ix
          pop  hl
          inc  hl
          inc  hl
          push hl
          ld   de,filen
          ld   bc,12
          ldir
          pop  hl
          ret
          
          
;Check to make sure we have a
;";" or "," before a variable
;filename, or if we go direct
;into a filename, done so
;that compat is retained...
          
cksemi:   cp    ','  
          jp    z,rout32  
          cp    ';'  
          jp    z,rout32  
          cp    '"'  
          ret   z  
          jp    nonerr  

;Overall check for P*[1,2] routine..

getdrv:   call rout32
getdrv1:  and  223
          cp   'P'
          jr   nz,nonerr
getdrv2:  call rout32

          
;Get the drive - from basic
          
gdrive:   cp    '*'  
          jr    z,chadd  
          call  expt1n  
          call  rout24  
          call  syntax  
          ret   z  
          push  af  
          call getnum
          ld    a,b  
          and   a  
          jr    nz,idveer  
          ld    a,c  
          cp    3  
          jr    nc,idveer  
          and   a  
          jr    z,idveer  
          ld    (curdrv),a  
          pop   af  
          ret   
chadd:    call  rom3  
          dw    74h ;chadd  
          ret   
          
idveer:   call  errorn  
          db    36 ;invalid device  
nonerr:   call  errorn  
          db    11  
;varerr:   call  errorn  
;          db    1  
bfnerr:   call  errorn  
          db    33  
;parerr:   call  errorn  
;          db    45  
          
;Check for end of line & also
;for syntax
          
ckend:    call  rout24  
          call  ckenqu  
          jr   nz,nonerr	;Not end of statement, call nonsense in basic
ckend1:   ld    (iy+0),255  	;No error
          set   7,(iy+1)  
          call  syntax  	;Checks if we're doing syntax
          ret   nz  		;We're not, so execute the command
          res   7,(iy+1)  
          pop   bc  
          jp    synexe  	;Carry on syntax checking
          
;
; Checks for end of statement
; Entry:	a = character to check
; Exit:		z = end of statement/ nz = not end of statement
;

ckenqu:   cp    13  
          ret   z  
          cp    58  
          ret   
          
syntax:   bit   7,(iy+48)  
          ret   
          
usezer:   call  syntax  
          ret   z  
          ld    bc,0  
          call  rom3  
          dw    11563  
          ret   
          
          
errorn:   pop   hl  
          ld    a,(hl)  
          ld    (iy+0),a  
;Not required - 23/2/98
;          ld    hl,flags  
          jp   scan1


getnum:   call rom3
          dw   fnint2
          ret
          
rout32:   call  rom3  
          dw    32  
          ret   

rout24:   call rom3
          dw   24
          ret

setchan:  call rom3
          dw   5633
          ret

;Pick up byte from 48k memory
gfropg:   call rom3
          dw   123
          ret
          
e32_1n:   call  rout32  
expt1n:   call  rom3  
          dw    9467  
          bit   6,(iy+1)  
          ret   nz  
          pop   bc  
          call  errorn  
          db    11  
          
exptex:   call  rom3  
          dw    9467  
          bit   6,(iy+1)  
          ret   z  
          pop   bc  
          call  errorn  
          db    11  
          
print:    call  rom3  
          dw    16  
          ret   

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
          

; Wait for a keypress
; Exit:		z = [Yy] was pressed, nz = otherwise

confim:   set   5,(iy+2)
          call  rom3
          dw    15D4h ;Wait key
          and 223
          cp 'Y'
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
          
;Converter for +3 errors
;Check for hook codes, if so should return with error in a
errou:
errou2:   ld    c,a  
          ld    b,0  
          ld    hl,contab  
          add   hl,bc  
          ld    a,(hl)  
          ld    (errou1),a  
          call  errorn  
errou1:   db    0  
          
cjump:    jp    (iy)
          
;Cut out the bad filename crap

spstor:   dw   0


xdpb:     db    36,0,4,15,0,100,1
          db    127,0,192,0,32,0,1,0
          db    2,3,129,80,9,1,0,2
          db    42,82,96,0

;Table to convert +3 DOS errors
;(values 0-9 & 20-36) into rst 8
;codes
          
contab:   db    61,62,63,64,65,66  
          db    67,68,69,70  
          db    0,0,0,0,0  
          db    0,0,0,0,0  
          db    44,45,46,47,48,49  
          db    50,51,52,53,54  
          db    55,56,57,58,59,60  
        
