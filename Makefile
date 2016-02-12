INSTALLDIR = ~/Desktop/Kerbal\\\ Space\\\ Program/Ships/Script
STAGEDIR = packed

files := $(wildcard *.ks)
packed := $(foreach file, $(files:.ks=.ksp), $(STAGEDIR)/$(file))
installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))

all : $(packed)

$(STAGEDIR)/%.ksp : %.ks
	/bin/sed -e 's|^\(\([^"]*\)\("[^"]*"[^"]*\)*\)\s*//.*$$|\1|g' -e 's|^\(\([^"]*\)\("[^"]*"[^"]*\)*\)\s*//.*$$|\1|g' -e 's|^\s*||g' -e 's|\s*$$||g' -e '/^$$/d' $< > $@;

$(INSTALLDIR)/%.ks : $(STAGEDIR)/%.ksp
	cp $< $@;

install : $(installed)

clean :
	rm $(packed)
