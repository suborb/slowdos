;
;       Slowdos Source Code
;
;
;       $Id: loadsynt.asm,v 1.1 2003/06/14 23:08:18 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/14 23:08:18 $
;
;	Handle load/save syntax parsing

 
comtyp:   db    0
          
; Load/save/merge syntax checking
; Syntax:
;
; LOAD Pdd"f"[S][!]
; LOAD Pdd"f" SCREEN$
; LOAD Pdd"f" DATA
; LOAD Pdd"f" CODE [a][,d]
; LOAD @dd,tt,ss,aa

          
;The beefy load routine...
          
load:     ld    a,1  		; Indicate "LOAD"
load0:    ld    (comtyp),a  
          call  rout32  	; Check for '@'
          cp    '@'  
          jp    z,seclod  	; Was a '@' goto the sector load routine
          jr   loadud

save:     xor   a  		; Indicate "SAVE"
          jr    load0  
          
verify:   ld    a,2  		; Indicate "VERIFY"
          jr    merge1  

;And the merge routine
          
merge:    ld    a,3  		; Indidcate "MERGE"
merge1:   ld    (comtyp),a  
          call  rout32  
                    
          
loadud:   call  getdrv1         ; Get drives, enter with next char in a
          call  cksemi  	; Look for a semi colon,comma,double quote
          
;0=save, 1=load,2=verify,3=merge

savetc:   ld    a,(comtyp)
          call  settap		;??
          ld    ix,ufia  
          call  exptex  	; We want a string
          call  syntax  	; Check if in syntax mode
          jr    z,sadata  	; If we're in syntax don't touch variables
          ld   hl,flags
          res  5,(hl)
          call  clufia  	; clear ufia filename, hl = ufia+2
          ld    (ix+15),0	; clear directory flags
          call  getstr  	; Get the string into ufia+2
          jr    z,sadata	; Valid filename
          ld    hl,flags3	; Filename is wild, check if in .TAP mode
          bit   0,(hl)    
          jp    z,bfnerr 	; Not in .TAP mode - bad filename
sadata:   call  rout24  	; Check for a '!'
          cp    '!'
          jr    nz,sadat0
          ld    hl,flags	; If so, then indicate headerless mode
          set   5,(hl)
          call  rout32		; Get next character
sadat0:   cp    228     	; DATA
          jr    nz,sascr  
          ld    a,(comtyp)  	; Check command, if MERGE then Nonsense in BASIC
          cp    3  
          jp    z,nonerr  
          call  rout32  
          call  rom3  
          dw    28B2h ; look vars  
          set   7,c  
          jr    nc,savold  
          ld    hl,0  
          ld    a,(comtyp)  
          dec   a  
          jr    z,savnew  
          call  errorn  
          db    1   ;var not found  
savold:   jp    nz,nonerr  
          call  syntax  
          jr    z,sadat1  
          inc   hl  
;Copy the length...
          call gfropg
          ld    (ix+16),a  
          inc   hl  
          call gfropg
          ld    (ix+17),a  
          inc   hl  
;Variable name...
savnew:   call  syntax  
          jr    z,sadat1  
          ld    (ix+19),c  
          ld    a,1  
          bit   6,c  
          jr    z,savtyp  
          inc   a  
;Save the file type...
savtyp:   ld    (ix+15),a  
sadat1:   ex    de,hl  
          call  rout32  
          cp    ')'  
          jp    nz,nonerr  ;nonerr  
          call  rout32  
          call  ckend  
          ex    de,hl  
          jp    saall  

sascr:    cp    170  		;SCREEN$
          jr    nz,sacod  
          ld    a,(comtyp)  	; MERGE is not an appropriate type
          cp    3  
          jp    z,nonerr  
          call  rout32  
          call  ckend  		; Check for end
          ld    (ix+16),0  	; Set up file length and start for SCREEN$
          ld    (ix+17),27  
          ld    hl,16384  
          ld    (ix+18),l  
          ld    (ix+19),h  
          jr    satyp3  	; hl = load address
sacod:    cp    175  		;CODE
          jr    nz,saline  
          ld    a,(comtyp)  	; Once more MERGE is not an appropriate command
          cp    3 
          jp    z,nonerr  
          call  rout32  
          call  ckenqu  	; Check for end
          jr    nz,sacod1  	; Jump if more parameters
          ld    a,(comtyp)  	; SAVE with no parameters makes no sense
          and   a  
          jp    z,nonerr  
          call  usezer  	; Stack 0 for first parameter
          jr    sacod2  

sacod1:   call  expt1n  	; Get a number (we already have 1 char)
          call  rout24  	; Check for comma
          cp    ','  
          jr    z,sacod3  
          ld    a,(comtyp)  	; If SAVE and only one parameter then nonsense
          and   a  
          jp    z,nonerr  
sacod2:   call  usezer  	; Stack 0 for second parameter
          jr    sacod4
sacod3:   call  e32_1n  	; Get second parameter
sacod4:   call  ckend  		; End of line
          call getnum		; Get second parameter
          ld    (ix+16),c  	; Save length in ufia
          ld    (ix+17),b  
          call getnum		; Get first parameter
          ld    (ix+18),c  	; Save load address in ufia
          ld    (ix+19),b  
          ld    h,b  		; hl = load address
          ld    l,c  
;Code +scr$ types...
satyp3:   ld    (ix+15),3  	; Indicate filetype CODE expected
          jr    saall  

; Snapshot handling
saline:   and   223  
          cp    'S'  
          jr    nz,salin1  
          call  rout32 		; Get next character
          ld    b,48 		;value for 32765 (lock)
          ld    h,176  		;ldir
          ld    l,237
          cp    '!'		; '!' not supplied thus lock paging
          jr    nz,snap0
          call  rout32
          ld    b,16		; Normal unlocked memory setup
          ld    hl,0		; Don't copy the printer buffer
snap0:    ld    a,b
          ld    (lmode+1),a	; Save locked mode
          ld    (cpbuff),hl	; Save the printer buffer copying opcode
          call   ckend  	; Check for end
          ld     a,(comtyp)  	; Anything apart from LOAD doesn't make sense
          dec    a  
          jp     nz,nonerr  
          ld     (ix+15),4  	; Indicate snapshot type
          jr     saall  

; So, it must be BASIC then
salin1:   cp    202 		;LINE
          jr    z,salin0  	; Jump if we had a LINE parameter
          call  ckend  		; Otherwise check for end
          ld    (ix+18),0  	; Set up load address
          ld    (ix+19),80  
          jr    satyp0  

salin0:   ld    a,(comtyp)  	; We can't have a LINE without SAVE type
          and   a  
          jp    nz,nonerr  
          call  e32_1n  	; Get number
          call  ckend  		; Check for end of statemetn
          call  getnum		; Get line number off the stack
          ld    (ix+18),c  	; And place it in the ufia
          ld    (ix+19),b  
satyp0:   ld    (ix+15),0  	; Indicate BASIC type
          ld    hl,(23641)  	; Calculate length of BASIC program
          ld    de,(23635)  
          scf   
          sbc   hl,de  
          ld    (ix+16),l  	; And place in ufia
          ld    (ix+17),h  
          ld    hl,(23627)  	; Calculate length of variables
          sbc   hl,de  
          ld    (ix+20),l  	; And place in ufia
          ld    (ix+21),h  
          ex    de,hl  		; hl = (23635) = load address
saall:    ld    a,(comtyp)  	; If commmand type is SAVE, goto save routine
          and   a  
          jp    z,sacntl  
          cp    2  		; If its verify, then silently ignore
          ret   z  
          ld    (saall2+1),hl  
          call  rdopen  	; Open the file

saall0:   ld    a,(temphd)	; Check disc header versus our ufia
          cp    (ix+15)
          jr    z,saall1
          call  errorn
          db    29  		;Wrong file type
saall1:   cp    4  		; If it's a snapshot, goto snapshot handler
          jp    z,snpcnt  
saall2:   ld    hl,0  		; Modified by above, contains load address
          cp    3  		; CODE filetype
          jr    z,vrcntl  	
          ld    a,(comtyp)  	; So it must be BASIC/DATA Check for command LOAD
          dec   a  
          jr    z,ldcntl  
          cp    2  		; Check for MERGE
          jp    z,mecntl  	

; Handles loading CODE/SCREEN$
vrcntl:   push  hl  		; Save load address
          ld    l,(ix+16)  	; Get file length
          ld    h,(ix+17)  
          ld    bc,(temphd+1)  	; Disc length
          ld    a,l  		; If specified file length == 0 then skip checks
          or    h  
          jr    z,vrcnt1  
          sbc   hl,bc  
          jr    c,repotr  	; Incorrect file length
          jr    z,vrcnt1  
          ld    a,(ix+15)  	; No check that we requested a CODE file
          cp    3  
          jr    nz,repotr  
vrcnt1:   pop   hl  		; Check load address, if 0 then use file address
          ld    a,h  
          or    l  
          jr    nz,vrcnt2  
          ld    hl,(temphd+3)  	; Pick up file load address
vrcnt2:   ex    de,hl  		; de = load address, bc = length to load
ldblok:   jp    rdblok  
          
repotr:   call  errorn  
          db    79   		;code length  
          
;For basic progs +arrays
ldcntl:   ld    de,(temphd+1)   ; File length
          push  hl  		; Store load address
          ld    a,h  
          or    l  
          jr    nz,ldcnt1  
          inc   de  
          inc   de  
          inc   de  
          ex    de,hl  
          jr    ldcnt2  
ldcnt1:   ld    l,(ix+16)  	; Get BASIC program length
          ld    h,(ix+17)  
          ex    de,hl  
          scf   
          sbc   hl,de  
          jr    c,lddata  
ldcnt2:   ld    de,5  
          add   hl,de  
          ld    b,h  
          ld    c,l  
          call  rom3  
          dw    1F05h  ; test room  
lddata:   pop   hl  
          ld    a,(ix+15)  	; If file type is BASIC
          and   a  
          jr    z,ldprog  
          ld    a,h  
          or    l  
          jr    z,lddat1  
          dec   hl  
          ld    b,(hl)  
          dec   hl  
          ld    c,(hl)  
          dec   hl  
          inc   bc  
          inc   bc  
          inc   bc  
          ld    (23647),ix  ; xptr  
          call  rom3  
          dw    19E8h ; reclaim 2  
          ld    ix,(23647)  
lddat1:   ld    hl,(23641)  
          dec   hl  
          ld    bc,(temphd+1)  
          push  bc  
          inc   bc  
          inc   bc  
          inc   bc  
          ld    a,(ix+19) ;variable  
          push  af  
          call  rom3  
          dw    1655h  ;make room  
          inc   hl  
          pop   af  
          ld    (hl),a  
          pop   de  
          inc   hl  
          ld    (hl),e  
          inc   hl  
          ld    (hl),d  
          inc   hl  
          ex    de,hl  
          push  hl  
          pop   bc  
          jp    ldblok  
          
ldprog:   ex    de,hl  
          ld    hl,(23641)  
          dec   hl  
          ld    (23647),ix  
          ld    bc,(temphd+1)  
          push  bc  
          call  rom3  
          dw    19E5h ; reclaim 1  
          pop   bc  
          push  hl  
          push  bc  
          call  rom3  
          dw    1655h ; make room  
          ld    ix,(23647)  
          inc   hl  
          ld    bc,(temphd+5) ;n len  
          add   hl,bc  
          ld    (23627),hl  
          ld    hl,(temphd+3) ;LINE
          ld    a,h  
          and   11000000b  
          jr    nz,ldprg1  
          ld    (23618),hl  
          ld    (iy+10),0  
ldprg1:   pop   bc  
          pop   de  
          jp    ldblok  
          
;Loading 48k snapshots
;This bit of code will be rewritten
;To handle .sna

basreg:   equ  wrisec

snpcnt:   ld   a,23
          ld   (page),a
;          ld   de,wrisec+256
          ld   de,basreg
          ld   bc,27
          call rdblok
;          ld   hl,basreg+1
;          ld   de,wrisec
;          ld   bc,18
;          ldir
          ld   a,(basreg)  ;a=i
          ld   (imval+1),a
;Do ei/di
          ld   b,243
          ld   a,(basreg+19)
          bit  2,a
          jr   z,snpcn1
          ld   b,251
snpcn1:   ld   a,b
          ld   (snppa4),a
          ld   hl,(basreg+25)  ;l=im 0/1/2,h=border colour
          ld   a,l
          ld   (immode+1),a
          ld   a,h
          ld   (bordcr+1),a
          ld   a,(basreg+20)
          ld   (valr+1),a
          ld   hl,(basreg+21) ;af
          ld   (snppa5),hl
          ld   hl,(basreg+23) ;sp
          ld   (snppa3+1),hl

          ld    de,16384  	; Read in the screen within the .sna file
          ld    bc,6912  
          call  rdblok  
bordcr:   ld   a,0		; Change the border colour
          out  (254),a
          ld    a,23  		; Read the printer buffer to somewhere safe
          ld    (page),a  
          ld    de,wrisec+256  
          ld    bc,256  
          call  rdblok  
          ld    a,16  		; Now read the rest of the code
          ld    (page),a  
          ld    de,23296+256  
          ld    bc,41984  
          call  rdblok  
          ld    hl,wrisec+256  	; Copy the printer buffer
          ld    de,23296  
          ld    bc,256  
cpbuff:   ldir  		; Will either be ldir/nop-nop depending
          di    		; Restore some of the standard registers
          im    1  
          ld    sp,basreg+1  
          pop  hl
          pop  de
          pop  bc
          pop  af
          exx
          ex   af,af'
          pop  hl
          pop  de
          pop  bc
          pop  iy
          pop  ix
imval:    ld   a,0
          ld    i,a  
immode:   ld    a,0  
          bit   2,a  
          jr    z,noim2  
          im    2  
noim2:    ld    (snppa1+1),bc  
          push  hl  
          push  de  
          ld    hl,snppag  
          ld    de,16384  
          ld    bc,snpend-snppag 
          ldir  
          pop   de  
          pop   hl  
          ld    sp,(snppa5-snppag+16384)  
          jp    16384  
          
snppag:   ld    bc,32765  
          ld    a,16  
          out   (c),a  
lmode:    ld    a,48  
          out   (c),a  
snppa1:   ld    bc,0  
valr:     ld   a,0
          ld    r,a  
          pop  af
snppa3:   ld   sp,0
snppa4:   ei
          ret
snppa5:   dw   0
snpend:
          
          
;Merge control routine
          
mecntl:   ld    bc,(temphd+1)  
          push  bc  
          inc   bc  
          call  rom3  
          dw    48 ;bc spaces  
          ld    (hl),128  
          pop   bc  
          push  de  
          call  rdblok  
          pop   hl  
          ld    de,(23635)  
          call  rom3  
          dw    08D2h ; me-new-lp  
          ret   


; Save file routine
sacntl:   push  hl  		; hl = save address
sacntl1:  call  wropen  	; Open the file
          pop   de  		; Get the save address back
          ld    c,(ix+16)  	; Pick up the length from the ufia
          ld    b,(ix+17)  
          call  wrblok  	; Write the block
          jp    wrclos  	; And close

          
; Sector load routine
          
seclod:   call  rout32  
          call  gdrive  	; get the drive
          call  rout24  	; we need a comma
          cp    ','  
          jp    nz,nonerr  
          call  e32_1n  	; get track
          cp    ','  
          jp    nz,nonerr  
          call  e32_1n  	; get sector
          cp    ','  
          jp    nz,nonerr  
          call  e32_1n  	; get load address
seclo0:   call  ckend  		; check for end of statement
          call  getnum		; get address off stack
          ld    (lodadd),bc  
          call  getnum		; get sector off stack
          ld    a,b  		; Check for sector > 255
          and   a  
          jr    z,seclo1
parerr:   call  errorn
          db    45   ;parameter error
seclo1:   ld    a,c  
          ld    (sect),a  
          call  getnum		; get track off disc
          ld    a,b  		; check for track > 255
          and   a  
          jr    nz,parerr  
          ld    a,c  
          ld    (sect+1),a  
seclo3:   ld    de,(sect)  
          ld    hl,(lodadd)  
          ld    a,(comtyp)  	; check command type
          and   a  		; SAVE
          jp    z,wos  
          jp    ros		; READ

lodadd:   dw    0		;VARIABLE
sect:     dw    0		;VARIABLE

;Routine to set bit 6,(flags) if bit 6,(flags2)..
;Entry:   a=comtyp - if not relevent set to <>0

settapn:  xor  a
settap:   ld   hl,flags2
          bit  6,(hl)
          ret  z
          inc  hl   ;hl=flags3
          res  0,(hl)
          and  a
          ret  z
          set  0,(hl)    ;have marked that we're in there!!
          ret
