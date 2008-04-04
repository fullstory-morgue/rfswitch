#
# Makefile for the SW RF Switch kernel modules
#
# NOTE: This make file can serve as both an external Makefile (launched
#       directly by the user), or as the sub-dir Makefile used by the kernel
# 	build system.


CONFIG_AVERATEC_5100P=m
CONFIG_PACKARDBELL_E5=m



list-m :=
list-$(CONFIG_AVERATEC_5100P) += av5100
list-$(CONFIG_PACKARDBELL_E5) += pbe5


obj-$(CONFIG_AVERATEC_5100P) += av5100.o
obj-$(CONFIG_PACKARDBELL_E5) += pbe5.o

#
# Begin dual Makefile mode here.  First we provide support for when we
# are being invoked by the kernel build system
#
ifneq ($(KERNELRELEASE),)

ifneq ($(PATCHLEVEL),6) # If we are not on a 2.6, then do 2.4 specific things

O_TARGET := rfswitch.o

include $(TOPDIR)/Rules.make

endif # End if 2.4 specific settings

else 
# Here we begin the portion that is executed if the user invoked this Makefile
# directly.

# KSRC should be set to the path to your sources
# modules are installed into KMISC
KVER  := $(shell uname -r)
KSRC := /lib/modules/$(KVER)/build
KMISC := /lib/modules/$(KVER)/kernel/drivers/net/wireless/

# KSRC_OUTPUT should be overridden if you are using a 2.6 kernel that
# has it's output sent elsewhere via KBUILD_OUTPUT= or O=
KSRC_OUTPUT := $(KSRC)

# If we find Rules.make, we can assume we're using the old 2.4 style building
OLDMAKE=$(wildcard $(KSRC)/Rules.make)
PWD=$(shell pwd)

VERFILE := $(KSRC_OUTPUT)/include/linux/version.h
KERNELRELEASE := $(shell \
	if [ -r $(VERFILE) ]; then \
		(cat $(VERFILE); echo UTS_RELEASE) | \
		$(CC) -I$(KSRC_OUTPUT) $(CFLAGS) -E - | \
		tail -n 1 | \
		xargs echo; \
        else \
		uname -r; \
	fi)

MODPATH := $(DESTDIR)/lib/modules/$(KERNELRELEASE)

all: modules

clean:
	rm -f *.mod.c *.mod *.o *.ko .*.cmd .*.flags Modules.symvers
	rm -rf $(PWD)/tmp


ifeq ($(OLDMAKE),)

TMP=$(PWD)/tmp
MODVERDIR=$(TMP)/.tmp_versions

modules:
ifdef ($(KSRC_OUTPUT)/.tmp_versions)
	mkdir -p $(MODVERDIR)
	-cp $(KSRC_OUTPUT)/.tmp_versions/*.mod $(MODVERDIR)
endif
ifeq ($(KSRC),$(KSRC_OUTPUT)) # We're not outputting elsewhere
ifdef ($(KSRC)/.tmp_versions)
	-cp $(KSRC)/.tmp_versions/*.mod $(MODVERDIR)
endif
	$(MAKE) -C $(KSRC) SUBDIRS=$(PWD) MODVERDIR=$(MODVERDIR) modules
else # We've got a kernel with seperate output, copy the config, and use O=
	mkdir -p $(TMP)
	cp $(KSRC_OUTPUT)/.config $(TMP)
	$(MAKE) -C $(KSRC) SUBDIRS=$(PWD) MODVERDIR=$(MODVERDIR) O=$(PWD)/tmp modules
endif

install: modules
	install -d $(KMISC)
	install -m 644 -c $(addsuffix .ko,$(list-m)) $(KMISC)
	/sbin/depmod -a


else # We're on 2.4, and things are slightly different

modules:
	$(MAKE) -C $(KSRC) SUBDIRS=$(PWD) BUILD_DIR=$(PWD) modules

install: modules
	install -d $(KMISC)
	install -m 644 -c $(addsuffix .o,$(list-m)) $(KMISC)
	/sbin/depmod -a

endif

uninstall:
	cd $(KMISC)
	rm -rf $(addsuffix .ko,$(list-m))
	cd -
	/sbin/depmod -a

endif
