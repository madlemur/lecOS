INSTALLDIR = ~/Desktop/Kerbal\ Space\ Program/Ships/Script
STAGEDIR = packed
MISSIONINSTALLDIR = $(INSTALLDIR)/Missions
MISSIONSTAGEDIR = $(STAGEDIR)/Missions
BOOTINSTALLDIR = $(INSTALLDIR)/boot
BOOTSTAGEDIR = $(STAGEDIR)/boot
LIBINSTALLDIR = $(INSTALLDIR)/lib
LIBSTAGEDIR = $(STAGEDIR)/lib
RAMPINSTALLDIR = $(INSTALLDIR)/ramp
RAMPSTAGEDIR = $(STAGEDIR)/ramp

# File where to store auto increments
BLD_VER_FILE ?= .buildver
BLD_RLS_FILE ?= .buildrls
BLD_PTC_FILE ?= .buildptc

# Initiate BLD_FILE if not exists
buildver_create := $(shell if ! test -f $(BLD_VER_FILE); then echo 0 > $(BLD_VER_FILE); fi)
buildrls_create := $(shell if ! test -f $(BLD_RLS_FILE); then echo 0 > $(BLD_RLS_FILE); fi)
buildptc_create := $(shell if ! test -f $(BLD_PTC_FILE); then echo 0 > $(BLD_PTC_FILE); fi)

files := $(wildcard *.ks)
missions := $(notdir $(wildcard Missions/*.ks))
boots := $(notdir $(wildcard boot/*.ks))
libs := $(notdir $(wildcard lib/*.ks))
ramp := $(notdir $(wildcard ramp/*.ks))
packed := $(foreach file, $(files:.ks=.ksp), $(STAGEDIR)/$(file))
installed := $(foreach file, $(files), $(INSTALLDIR)/$(file))
packedmissions := $(foreach file, $(missions:.ks=.ksp), $(MISSIONSTAGEDIR)/$(file))
installedmissions := $(foreach file, $(missions), $(MISSIONINSTALLDIR)/$(file))
packedboots := $(foreach file, $(boots:.ks=.ksp), $(BOOTSTAGEDIR)/$(file))
installedboots := $(foreach file, $(boots), $(BOOTINSTALLDIR)/$(file))
packedlibs := $(foreach file, $(libs:.ks=.ksp), $(LIBSTAGEDIR)/$(file))
installedlibs := $(foreach file, $(libs), $(LIBINSTALLDIR)/$(file))
packedramp := $(foreach file, $(ramp:.ks=.ksp), $(RAMPSTAGEDIR)/$(file))
installedramp := $(foreach file, $(ramp), $(RAMPINSTALLDIR)/$(file))

# Prepare callable function. This function updates BLD_FILE
buildver = $(shell echo $$(($$(cat $(BLD_VER_FILE)) + 1)) > $(BLD_VER_FILE))
buildrls = $(shell echo $$(($$(cat $(BLD_RLS_FILE)) + 1)) > $(BLD_RLS_FILE))
buildptc = $(shell echo $$(($$(cat $(BLD_PTC_FILE)) + 1)) > $(BLD_PTC_FILE))

all : $(STAGEDIR) $(packed) $(MISSIONSTAGEDIR) $(packedmissions) $(BOOTSTAGEDIR) $(packedboots) $(LIBSTAGEDIR) $(packedlibs) $(RAMPSTAGEDIR) $(packedramp)
	$(call buildptc)

install : $(INSTALLDIR) $(installed) $(MISSIONINSTALLDIR) $(installedmissions) $(BOOTINSTALLDIR) $(installedboots) $(LIBINSTALLDIR) $(installedlibs) $(RAMPINSTALLDIR) $(installedramp)

release :
	rm $(BLD_PTC_FILE)
	$(call buildrls)

version :
	rm -rf $(BLD_PTC_FILE) $(BLD_RLS_FILE) $(STAGEDIR)
	$(call buildver)

clean :
	rm -rf $(STAGEDIR); #$(packed) $(packedmissions) $(packedboots) $(packedlibs);

$(STAGEDIR) :
	mkdir $(STAGEDIR)

$(MISSIONSTAGEDIR) :
	mkdir $(MISSIONSTAGEDIR)

$(BOOTSTAGEDIR) :
	mkdir $(BOOTSTAGEDIR)

$(LIBSTAGEDIR) :
	mkdir $(LIBSTAGEDIR)

$(INSTALLDIR) :
	mkdir $(INSTALLDIR)

$(MISSIONINSTALLDIR) :
	mkdir $(MISSIONINSTALLDIR)

$(BOOTINSTALLDIR) :
	mkdir $(BOOTINSTALLDIR)

$(LIBINSTALLDIR) :
	mkdir $(LIBINSTALLDIR)

$(RAMPINSTALLDIR) :
	mkdir $(RAMPINSTALLDIR)

$(STAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' > $@;
	/bin/sed -i -e 's/BUILD_DATE/$(shell date +'%Y%m%d')/' $@;
	/bin/sed -i -e 's/BUILD_VERSION/$(shell cat $(BLD_VER_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_RELEASE/$(shell cat $(BLD_RLS_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_PATCH/$(shell cat $(BLD_PTC_FILE))/' $@;

$(MISSIONSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' > $@;
	/bin/sed -i -e 's/BUILD_DATE/$(shell date +'%Y%m%d')/' $@;
	/bin/sed -i -e 's/BUILD_VERSION/$(shell cat $(BLD_VER_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_RELEASE/$(shell cat $(BLD_RLS_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_PATCH/$(shell cat $(BLD_PTC_FILE))/' $@;

$(BOOTSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' > $@;
	/bin/sed -i -e 's/BUILD_DATE/$(shell date +'%Y%m%d')/' $@;
	/bin/sed -i -e 's/BUILD_VERSION/$(shell cat $(BLD_VER_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_RELEASE/$(shell cat $(BLD_RLS_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_PATCH/$(shell cat $(BLD_PTC_FILE))/' $@;

$(LIBSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' > $@
	/bin/sed -i -e 's/BUILD_DATE/$(shell date +'%Y%m%d')/' $@
	/bin/sed -i -e 's/BUILD_VERSION/$(shell cat $(BLD_VER_FILE))/' $@
	/bin/sed -i -e 's/BUILD_RELEASE/$(shell cat $(BLD_RLS_FILE))/'  $@
	/bin/sed -i -e 's/BUILD_PATCH/$(shell cat $(BLD_PTC_FILE))/' $@

$(RAMPSTAGEDIR)/%.ksp : %.ks
	./packer.sed < $< | /bin/sed -e 's|^\s*\(.*\)\s*$$|\1|g' -e '/^$$/d' > $@;
	/bin/sed -i -e 's/BUILD_DATE/$(shell date +'%Y%m%d')/' $@;
	/bin/sed -i -e 's/BUILD_VERSION/$(shell cat $(BLD_VER_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_RELEASE/$(shell cat $(BLD_RLS_FILE))/' $@;
	/bin/sed -i -e 's/BUILD_PATCH/$(shell cat $(BLD_PTC_FILE))/' > $@;

$(INSTALLDIR)/%.ks : $(STAGEDIR)/%.ksp
	cp $< '$@';

$(MISSIONINSTALLDIR)/%.ks : $(MISSIONSTAGEDIR)/%.ksp
	cp $< '$@';

$(BOOTINSTALLDIR)/%.ks : $(BOOTSTAGEDIR)/%.ksp
	cp $< '$@';

$(LIBINSTALLDIR)/%.ks : $(LIBSTAGEDIR)/%.ksp
	cp $< '$@';

$(RAMPINSTALLDIR)/%.ks : $(RAMPSTAGEDIR)/%.ksp
	cp $< '$@';
