INSTALLDIR = ~/Desktop/Kerbal\ Space\ Program/Ships/Script
STAGEDIR = packed
MISSIONINSTALLDIR = $(INSTALLDIR)/Missions
MISSIONSTAGEDIR = $(STAGEDIR)/Missions
BOOTINSTALLDIR = $(INSTALLDIR)/boot
BOOTSTAGEDIR = $(STAGEDIR)/boot

files := $(wildcard *.ks)
missions := $(notdir $(wildcard Missions/*.ks))
boots := $(notdir $(wildcard boot/*.ks))
packed := $(foreach file, $(files:.ks=.ksp), $(STAGEDIR)/$(file))
installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))
packedmissions := $(foreach file, $(missions:.ks=.ksp), $(MISSIONSTAGEDIR)/$(file))
installedmissions := $(foreach file, $(missions), $(MISSIONINSTALLDIR)/$(file))
packedboots := $(foreach file, $(boots:.ks=.ksp), $(BOOTSTAGEDIR)/$(file))
installedboots := $(foreach file, $(boots), $(BOOTINSTALLDIR)/$(file))

all : $(packed) $(packedmissions) $(packedboots)

install : $(installed) $(installedmissions) $(installedboots)

clean :
	rm $(packed) $(packedmissions);

$(STAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' '  > $@;

$(MISSIONSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' '  > $@;

$(BOOTSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' '  > $@;

$(INSTALLDIR)/%.ks : $(STAGEDIR)/%.ksp
	cp $< '$@';

$(MISSIONINSTALLDIR)/%.ks : $(MISSIONSTAGEDIR)/%.ksp
	cp $< '$@';

$(BOOTINSTALLDIR)/%.ks : $(BOOTSTAGEDIR)/%.ksp
	cp $< '$@';
