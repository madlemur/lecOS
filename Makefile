INSTALLDIR = ~/Desktop/Kerbal\ Space\ Program/Ships/Script
STAGEDIR = packed
MISSIONINSTALLDIR = $(INSTALLDIR)/Missions
MISSIONSTAGEDIR = $(STAGEDIR)/Missions
BOOTINSTALLDIR = $(INSTALLDIR)/boot
BOOTSTAGEDIR = $(STAGEDIR)/boot
CRAFTINSTALLDIR = $(INSTALLDIR)/craft
CRAFTSTAGEDIR = $(STAGEDIR)/craft
LIBINSTALLDIR = $(INSTALLDIR)/lib
LIBSTAGEDIR = $(STAGEDIR)/lib

GIT_VERSION := $(shell git describe --abbrev=4 --dirty --always --tags)

files := $(wildcard *.ks)
missions := $(notdir $(wildcard Missions/*.ks))
boots := $(notdir $(wildcard boot/*.ks))
crafts := $(notdir $(wildcard craft/*.ks))
libs := $(notdir $(wildcard lib/*.ks))
packed := $(foreach file, $(files:.ks=.ksp), $(STAGEDIR)/$(file))
installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))
packedmissions := $(foreach file, $(missions:.ks=.ksp), $(MISSIONSTAGEDIR)/$(file))
installedmissions := $(foreach file, $(missions), $(MISSIONINSTALLDIR)/$(file))
packedboots := $(foreach file, $(boots:.ks=.ksp), $(BOOTSTAGEDIR)/$(file))
installedboots := $(foreach file, $(boots), $(BOOTINSTALLDIR)/$(file))
packedcrafts := $(foreach file, $(crafts:.ks=.ksp), $(CRAFTSTAGEDIR)/$(file))
installedcrafts := $(foreach file, $(crafts), $(CRAFTINSTALLDIR)/$(file))
packedlibs := $(foreach file, $(libs:.ks=.ksp), $(LIBSTAGEDIR)/$(file))
installedlibs := $(foreach file, $(libs), $(LIBINSTALLDIR)/$(file)) 

all : $(packed) $(packedmissions) $(packedboots) $(packedcrafts) $(packedlibs)

install : $(installed) $(installedmissions) $(installedboots) $(installedcrafts) $(installedlibs)

clean :
	rm $(packed) $(packedmissions) $(packedboot) $(packedcrafts) $(packedlibs);

$(STAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' ' | /bin/sed -e 's/%VERSION_NUMBER%/$(GIT_VERSION)/' > $@;

$(MISSIONSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' ' | /bin/sed -e 's/%VERSION_NUMBER%/$(GIT_VERSION)/'  > $@;

$(BOOTSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' ' | /bin/sed -e 's/%VERSION_NUMBER%/$(GIT_VERSION)/'  > $@;

$(CRAFTSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' ' | /bin/sed -e 's/%VERSION_NUMBER%/$(GIT_VERSION)/'  > $@;

$(LIBSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' | /bin/tr '\n' ' ' | /bin/sed -e 's/%VERSION_NUMBER%/$(GIT_VERSION)/'  > $@;

$(INSTALLDIR)/%.ks : $(STAGEDIR)/%.ksp
	cp $< '$@';

$(MISSIONINSTALLDIR)/%.ks : $(MISSIONSTAGEDIR)/%.ksp
	cp $< '$@';

$(BOOTINSTALLDIR)/%.ks : $(BOOTSTAGEDIR)/%.ksp
	cp $< '$@';

$(CRAFTINSTALLDIR)/%.ks : $(CRAFTSTAGEDIR)/%.ksp
	cp $< '$@';

$(LIBINSTALLDIR)/%.ks : $(LIBSTAGEDIR)/%.ksp
	cp $< '$@';
