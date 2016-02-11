files := $(wildcard *.ks)
packed := $(files:.ks=.ksp)

INSTALLDIR = %HOME%/Kerbal\\\ Space\\\ Program/Ships/Script

installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))

all : $(packed)

%.ksp : %.ks
	/bin/sed \
	-e 's|^\(\([^"]*\)\("[^"]*"[^"]*\)*\)\s*//.*$$|\1|g' \
	-e 's|^\(\([^"]*\)\("[^"]*"[^"]*\)*\)\s*//.*$$|\1|g' \
	-e 's|^\s*||g' -e 's|\s*$$||g' \
	-e '/^$$/d' \
	$< > $@;

$(INSTALLDIR)/%.ks : %.ksp
	cp $< $@;

install : $(installed)

clean :
	rm *.ksp
