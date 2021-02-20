

SOURCES = commands.asm fat.asm filename.asm loadsynt.asm mscat.asm  \
	  mscopy.asm mserase.asm msformat.asm msload.asm msmove.asm \
	  mssave.asm plus3.asm poke.asm print.asm syntax.asm storage.asm


all:	master

master:  joiner commands.bin booter.bin
	./joiner
	z88dk-appmake +zx -b slowdos.bin --org  32768 -o slowdos.tap

joiner: joiner.c
	gcc $^ -g -o $@


commands.bin: $(SOURCES:.asm=.o)
	z80asm -m -b -d -ocommands.bin  $^

booter.bin: booter.o
	z80asm -m -s -b -d -obooter.bin $^

%.o:	%.asm
	z80asm -o$@ $^


clean:
	rm -f *.bin *.obj *.sym *~ *.err   joiner *.o
	
