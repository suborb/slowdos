

SOURCES = commands.asm fat.asm filename.asm loadsynt.asm mscat.asm  \
	  mscopy.asm mserase.asm msformat.asm msload.asm msmove.asm \
	  mssave.asm plus3.asm poke.asm print.asm syntax.asm storage


all:	master

master:  commands.bin booter.bin
	./appmake


commands.bin: 
	z80asm -a -ns -m -ocommands.bin -easm $(SOURCES)

booter.bin:
	z80asm -a -ns -m -obooter.bin -easm booter.asm


clean:
	rm -f slowdos.bin *.obj *.sym *~ *.err 
	
