# Slowdos

Slowdos v2.x  (hereafter referred to as Slowdos), is an
extension to +3 BASIC which allows MSDOS discs to be read
and written from BASIC

Although there have already been a couple of programs which can
be run on the +3 which allow MSDOS discs to be used, they are
limited in scope: The original Slowdos only copied files, and
MSODBALL (by John Elliot) runs only from CP/M and uses an
obscure format which could be read by both MSDOS and CP/M.

Enter in here Slowdos, the program which allows all manner of
functions to be performed on MSDOS discs from BASIC.


## System Requirements

Slowdos will run on any +2a or +3 (hopefully regardless of
issue), however for practical usage a +3 with an external
disc-drive is recommended.

The external drive should be double-sided and capable of
reading 80 tracks ie a DSDD disc-drive. Slowdos has been
developed with 3.5" drives in mind, though there is no reason
why it shouldn't work with a DSDD 5.25" drive.

It is possible that Slowdos will work with single density
drives, although they to all intents and purposes obsolete, but
I make no guarantees as to data integrity.


## The new commands

A definitive list of commands now follows, it is not intented
to be a tutorial as to how to use them, it is presumed that the
concepts behind them is already known from use of the
equivalent +3 commands.

Key to symbols used:

a(n) = 16 bit number 
dd   = drive no 1,2,*
f    = filename
u1   = source filename
u2   = destination filename
ss   = stream number 

All parameters in parenthesis [ ] are optional.


### Essential disc filing commands

CAT [#ss,]dd"f"

Catalogues a disc, to stream ss (default is the screen), the
file name may be wild.  The displayed format is identical to
that of a normal +3 drive. NB Hidden (system) files are
automatically shown.


LOAD Pdd"f"

Load a file from the disc, all the usual BASIC extensions may
be used ie CODE, DATA, SCREEN$. In addition the extension S can
be used to load a 48k snapshot.

The snapshot format is the .SNA format, supported by all
emulators and is the de facto standard for 48k snapshots.


SAVE Pdd"f"[!]

Save a file to disc, as with LOAD all the usual BASIC 
extensions may be used. If ! is specified before any of the
BASIC extensions then the file is saved without a PLUS3DOS
compatible header


MERGE Pdd"f"   

Merge a BASIC file on disc with the one in memory


ERASE Pdd"f"   

Erase the file f from the disc


FORMAT Pdd[!][;"f"]

Format the current disc in DSDD MSDOS format. Confirmation is
asked prior to formatting. If ! is specified then the disc will
not be formatted, but merely initialised. The filename f is
the disc name, this is not used by Slowdos, but is provided for
ease of use of Slowdos formatted discs on other machines.



### Advanced disc commands

ERASE Pdd"u1" TO "u2"    

Rename the file u1 giving it the name u2


MOVE Pdd"f" TO #ss  

Copy the file f to the stream ss, note that file filtering
takes place, all character codes below 32 are replaced 
with a space.


COPY Pdd"u1" TO "u2"     

Copies the file named u1 on the MSDOS disc to the file named u2
on the default +3 drive. u2 may be a drive in which case u1 can
be wild, keeping the original filenames. Note that all the
files saved on the +3 disc will be saved with PLUS3DOS headers,
and if appropriate the headerdata filled to create files
loadable by +3 BASIC. The default for unrecognised files of
length shorter than 65535 bytes is to be a code file with a
load address of 0. 48k snapshots are saved as filetype 4.


COPY "u1" TO Pdd[!]["u2"]   

Copy the file u1 from the default +3 drive to the MSDOS disc.
If u1 is wild then omit u2. If the ! parameter is supplied then
the files saved on the MSDOS disc will be headerless.


LOAD @dd,tt,ss,aa

SAVE @dd,tt,ss,aa

These commands are used for reading/ writing disc sectors from
memory.  tt is the track, 0 - 79 (side 1), 80-159 (side 2). ss
is the sector number (1-9), and aa is the memory address in
memory configuration 5,2,0 (normal configuration)


MOVE TO Pdd"f"

Change directory, equivalent to the CD command on larger
computers. Inside each subdirectory there are always two
files. A "." file which refers to the current directory
and a ".." which points to the parent directory. 

A full path may be specifed by stringing directories together
thus:

MOVE TO pdd"dir1/dir2/dir3...."

Note the use of the / not \ - this is in line with all real
operating systems, UNIX, VAX, AmigaDOS etc

To move back to the root directory leave the pathname out or
make it null.

Once inside a subdirectory, usage of Slowdos is not affected,
it is still possible to load/save/copy/rename etc files.


### Compatibility Commands

VERIFY Ddd"f"

This commands are inoperative, they pass syntax to avoid
problems with programs that do use them.


POKE @a1,a2    

Does a 16 bit poke for the entire memory configuration (ROM3,
pages 5,2,7). This command is mainly supplied for small patches
to Slowdos (should they be needed), however it does have other
uses - try POKE 60433,col and POKE 60431,col to change the
editing colours for the top and bottom of the screen.


## Accessing Spectrum Emulator Files

Slowdos accesses a number of file formats used by emulators on
other machines. The most common of these is the snapshot file,
the usage of this was detailed above, but to recap:

LOAD Pdd"f"S  will load a 48K .SNA file and lock the machine in
              48k mode.

LOAD Pdd"f"S! will load a 48k .SNA but will not lock the +3 in
              48k mode. If you manage to break out of the
program then the chances are that you will be in 48k mode, but
you can return to 128k with Slowdos running via a PRINT USR
23354. Please note with this that crashes/spurious effects may
sometimes result whilst using the snapshot due to the fact that
data in the printer buffer isn't loaded.

Slowdos also supports the .TAP file format. A TAP file is in
essence an image of a cassette tape, and is often used to
preserve the loading screen of a game, it is also used by
Alchemist Software to distribute Alchnews for use on emulators.

Slowdos treats TAP files as (limited) sub-directories, limited
in the respect that they are not random access nor can a
CATalogue be performed. However it is possible to copy files
out of a TAP file to +3 disc.

To enter a TAP file use the command

MOVE TO Tdd"f"[IN]

Please note the use of T and not P (as for subdirectories). The
filename f must have the extension .TAP.

Once inside a TAP file the command LOAD P*"" may be issued to
load the first BASIC file found within it. As you may have
deduced it is necessary to prefix the filename with a P* - this
is so as to fail +3 syntax and to pass the command to Slowdos.
As a result it should be obvious that any program within the
TAP which loads files from BASIC will have to slightly modified
- namely the P* inserted before the filename. I believe that
this is a minor inconvenience when compared to the flexibility
that being able to access a TAP file provides.

Following logically, any program which loads headerless files
will not work, however it is possible to copy headerless files
to +3 disc, and then modify the program so that it does work
on a +3 - in essence converting the program back to its native
computer. The syntax of the COPY command is exactly the same
as for dealing with normal directories.


MOVE TO Tdd"f"OUT

This is a very powerful command which allows files on the +3 to
export files for use with emulators.

The file format used is (not unsuprisingly) the .TAP format, to
use it you can either copy files to it, or save files into it.

To close the .TAP file (when all the files are enclosed) do a
MOVE TO Tdd. The file will automatically be closed, and the
directory entry written. Please note that if you forget to do
this, then the .TAP will not be accessable, but space on the
disc will have been allocated.

As a little note to avoid any potential confusion, if you are
reading a .TAP file, any writing will take place in the current
directory, and if you are writing a .TAP file any reading will
access the current directory (on the MSDOS disc).

Unfortunately due to memory constraints it isn't possible to
copy files into a .TAP file from an MSDOS disc (and vice
versa).


## Usage of drives

Throughout the list of commands reference has been made to
drive numbers, however, since the +3 only supports one external
drive, there is only one MSDOS drive,and thus p1 and p2 access
the same physical drive.

Although the external drive is used by Slowdos, it is still
possible to perform +3 DOS functions on the B: drive, though
obviously it isn't possible to use both drives at the same time
eg copy from B: drive to MSDOS disc.

To this end, and in order to prevent corruption of +3 discs,
only discs which match a template MSDOS disc format will be
used by Slowdos, which rejects for use as MSDOS disc any
BFORMAT +3 discs. (Obviously it is possible to reformat these
discs for use by Slowdos).


## Error messages

All of the routines are fully error trapped and will return to
BASIC with a harmless error message should anything untoward
occur. In addition the RIC messages from +3 DOS have been
disposed of, any errors now result in an error message.


## General notes

It is well known that the +3 has problems driving certain
printers. A set of pokes was found which solved the problem,
however these shouldn't be used when Slowdos is installed
(crashes may result if you do), instead use POKE @49286,16
which will enable these problem printers to work. - Please note
that this POKE has changed from earlier versions of Slowdos and
DiSCDOS.

Slowdos survives the 128k NEW command, and need only be 
reloaded if a reset is performed.

Slowdos occupies the second screen (in page 7), and as such
nothing should be placed there lest the +3 crash in an
interesting manner! It also uses some additional space in page
7, this doesn't interfere with normal usage of the +3 though it
may cause some problems with other programs.


## Known bugs/feechures

Because of the +3 CAT syntax problem any CAT phrase involving a numeric variable will not be able to be entered unless the variable(s) exists. All other comands are unaffected, so the value of remedying it seems dubious.


## History

v1.0      Original version of program released back in 1994
??.8.94
v1.1      Bug release 
??.12.94

v2.0      Crippled demo version of the new Slowdos
5.12.97

v2.1      Fully featured version of the new Slowdos
7.12.97
(intern)

v2.2      Added .TAP, subdirectory support. Added the ! option
16.12.97  to snapshot loading. Optimized the code a lot.

v2.3      Added writing to .TAP files, added in system calls
2.3.98    (see Appendix II), incredible amount of optimization
          made - some 300 bytes saved! Sorted out erasing of
          files created on Sparc stations, cleaned up a
          potential problem in SAVEing of arrays.

v2.4      Full compatibility with +3B Syntax ROM,
24.2.2001 either english or spanish version



Appendix I - The snapshot file format
----------

The snapshot format supported by Slowdos is the common used
.SNA format derived from the Mirage Microdriver format. This is
the de facto standard for 48k snapshots and is supported by all
major emulators.

The format of the file is as follows:

Offset         Bytes     Description

0                1         i
1                2         hl'
3                2         de'
5                2         bc'
7                2         af'
9                2         hl
11               2         de
13               2         bc
15               2         iy
17               2         ix
19               1         Interrupt (bit 2=IFF2 1=EI/0=DI)
20               1         r
21               2         af
23               2         sp
25               1         Intmode (0=im0/1=im2/2=im2)
26               1         Border colour
27               49152     Ram dump (16384...65535)



Appendix II - System calls
-----------

As of v2.3, Slowdos gives you, the programmer, the ability to
access MSDOS discs in a simple way, without having to write
your own routines. Via these system calls you can do whatever
your imagination allows - for example you could read different
emulator file formats or you could write a file manager! - It's
up to you!

All of the calls, are referenced by calling address 49155 in
page 7 with l holding the routine number, at the moment, the
following routines are accessible:

1, r_mslog

Entry parameters:   none
Exit parameters:    standard

Log an MSDOS disc in, read in the FAT, check format


2, r_getpar

Entry parameters:   none
Exit parameters:    de=address of header in page 7

Get the address of the file header in page 7, this is 7 byte
block ala +3 DOS as is arranged as follows:

```
|----------------|-----|-----|-----|-----|-----|-----|-----|
|   Byte         |  0  |  1  |  2  |  3  |  4  |  5  |  6  |
|----------------|-----|-----|-----|-----|-----|-----|-----|
|Program         |  0  |File length|8000h/LINE |prog offset|
|Numeric array   |  1  |File length| xxx |name | xxx | xxx |
|Character Array |  2  |File length| xxx |name | xxx | xxx |
|Code            |  3  |File length| load addy | xxx | xxx |
|Snapshot        |  4  |File length| xxx | xxx | xxx | xxx |
|Longfile        |  5  |   32 bit file length  | xxx | xxx |
|----------------|-----|-----------------|-----|-----|-----|
```


3, r_rdopen

```
Entry parameters:   ix=ufia
Exit parameters:    standard
```

Open a file on the MSDOS disc for reading. If the file has a
standard +3 header, then this header is recognized, and the
header block filled out accordingly. If no header is present
and the file is <65536 bytes, then a header is faked such that
it is a CODE file with load address 0.


4, r_rdbyte

```
Entry parameters:   none
Exit parameters:    a=byte
```

Read a byte from the currently open file.


5, r_rdblok

```
Entry parameters:   de=address to load to
                    bc=number of bytes to read
                     h=page to load to
Exit parameters:    none
```

Read a chunk of code from the currently open file to memory in
the page given by h


6, r_wropen

```
Entry parameters:   ix=ufia
Exit parameters:    none
```

Open a file for reading, if the filetype in the ufia is specified as type 5, then no +3DOS style header will be created.


7, r_wrbyte

```
Entry parameters:   a=byte to write
Exit parameters:    none
```

Write the byte in a to the currently open file


8, r_wrblok

```
Entry parameters:   de=address of block
                    bc=length of block
                     h=RAM page
```

Write a block of memory to disc


9, r_wrclos

```
Entry parameters:   none
Exit parameters:    none
```

Close the currently open file, write the directory entry and
FAT.


10, r_erase

```
Entry parameters:   ix=ufia
Exit parameters:    none
```

Erase the files specified by the ufia - may be wild


11, r_snpload

```
Entry parameters:   none
Exit parameters:    none
```

Load the currently open reading file as a snapshot file, and
execute accordingly.


12, r_mscat

```
Entry parameters:   ix=ufia
Exit parameters:    none
```

Catalogue a disc directory matching the specifications of the
ufia.


13, r_mscatmem

```
Entry parameters:   ix=ufia
                    de=address to place catalogue
Exit parameters:    none
```

Catalogue the disc to an address in memory - make sure you
have sufficient room for the catalogue!!! Initialise the memory
with 0 before hand!!!

The format of the data supplied by the disc is unsorted and
is as follows:

```
byte 0    - number of files in directory (0-255)
The filename information is as follows:
     ds   11   - filename (without the ".")
     ds   1    - directory flags
     ds   2    - first cluster
     ds   4    - file length (32 bit)
```

- As can be seen, each directory entry requires 18 bytes of
space - this can amount to a lot - the routine does not respect
RAM pages so if you're not careful you could overwrite the
Slowdos code.

14,  r_seldir

```
Entry parameters:   de=path name
                    bc=length of path name
Exit parameters:    none
```

Move to the directory described by that in de


Notes:

If successful all of the routines will return with carry set,
if unsuccessful, carry will not be set, and a will hold the
"rst 8" error code - apologies for this, but memory is very
much at a premium!

The ufia (User File Information Area) is 20 bytes long and is
ordered as follows:

```
     +0   db   drive (0,1) (irrelevant)
     +1   db   stream (for r_mscat)
     +2   ds   filename (12 characters including ".")
     +14  db   directory flags (irrelevant)
     +15  db   filetype                 }
     +16  dw   filelength               } +3 header info
     +18  dw   start address/LINE/name  }
     +18  dw   offset to BASIC          }
```


Appendix III - Bonus program, Snapconv
------------

Snapconv is small program for the +3 which decomposes snapshot
files into smaller files that can be reconstructed to create a
+3 BASIC loadable program.

To use it, simply copy a snapshot file from an MSDOS disc the
default +3 drive, for practical purposes this must be A:.

If Snapconv is then loaded and the snapshot named entered, the
snapshot will be decomposed into 4 separate files, with
different extensions, but the same filename as the snapshot,
these files are as follows:

Extension      CODE parameters         

     .0            0,27    The registers detailed in Appendix I
     .1        16384,6912  Screendump
     .2        23296,1280  Printer buffer/BASIC area
     .3        24576,40960 Main code

It is then up to you to use the parts as you desire!!
