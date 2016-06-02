INSTALLDIR = /cygdrive/c/Program\ Files\ (x86)/Steam/steamapps/common/Kerbal\ Space\ Program/Ships/Script
STAGEDIR = packed
MISSIONINSTALLDIR = $(INSTALLDIR)
MISSIONSTAGEDIR = $(STAGEDIR)/Missions

files := $(wildcard *.ks)
missions := $(notdir $(wildcard Missions/*.ks))
packed := $(foreach file, $(files:.ks=.ksp), $(STAGEDIR)/$(file))
installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))
packedmissions := $(foreach file, $(missions:.ks=.ksp), $(MISSIONSTAGEDIR)/$(file))
installedmissions := $(foreach file, $(missions), $(MISSIONINSTALLDIR)/$(file))

all : $(packed) $(packedmissions)

install : $(installed) $(installedmissions)

clean :
	rm $(packed) $(packedmissions);

$(STAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' '  > $@;

$(MISSIONSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' '  > $@;
	
$(INSTALLDIR)/%.ks : $(STAGEDIR)/%.ksp
	cp $< '$@';

$(MISSIONINSTALLDIR)/%.ks : $(MISSIONSTAGEDIR)/%.ksp
	cp $< '$@';
