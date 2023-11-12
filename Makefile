#
# IMPORTANT NOTICE:
# !! This Makefile is no longer in use by me and i consider it obsolete.
# !! It *may* or *may not* build/install this plugin.
#
 

#/******************************************************************************
# * if you prefer verbose non-coloured build messages, remove the '@' here:
# *****************************************************************************/
CC  ?= @gcc
CXX ?= @g++

          
PWD = $(shell pwd)
PLUGIN = wirbelscancontrol
CPPSRC = $(wildcard *.c)
OBJS   = $(CPPSRC:%.c=%.o)
LDFLAGS?=

#/******************************************************************************
# * dependencies, add variables here, and checks in target check_dependencies
# *****************************************************************************/
#  LIBREPFUNC=librepfunc
#  LIBREPFUNC_MINVERSION=1.0.0
#

# /* require either PKG_CONFIG_PATH to be set, or, a working pkg-config */
#  HAVE_LIBREPFUNC           =$(shell if pkg-config --exists                                   $(LIBREPFUNC); then echo "1"; else echo "0"; fi )
#  HAVE_LIBREPFUNC_MINVERSION=$(shell if pkg-config --atleast-version=$(LIBREPFUNC_MINVERSION) $(LIBREPFUNC); then echo "1"; else echo "0"; fi )


DISTFILES = $(CPPSRC) $(wildcard *.h) po
DISTFILES+= COPYING HISTORY Makefile README

### The version number of this plugin (taken from the main source file):
VERSION = $(shell grep 'static const char \*VERSION *=' $(PLUGIN).c | awk '{ print $$6 }' | sed -e 's/[";]//g')

### The directory environment:
# Use package data if installed...otherwise assume we're under the VDR source directory:
PKGCFG = $(if $(VDRDIR),$(shell pkg-config --variable=$(1) $(VDRDIR)/vdr.pc),$(shell PKG_CONFIG_PATH="$$PKG_CONFIG_PATH:../../.." pkg-config --variable=$(1) vdr))
LIBDIR = $(call PKGCFG,libdir)
LOCDIR = $(call PKGCFG,locdir)
PLGCFG = $(call PKGCFG,plgcfg)

#
TMPDIR ?= /tmp

### The compiler options:
export CFLAGS   = $(call PKGCFG,cflags)
export CXXFLAGS = $(call PKGCFG,cxxflags)

### The version number of VDR's plugin API:
APIVERSION = $(call PKGCFG,apiversion)

### Allow user defined options to overwrite defaults:
-include $(PLGCFG)

### The name of the distribution archive:
ARCHIVE = $(PLUGIN)-$(VERSION)
PACKAGE = vdr-$(ARCHIVE)

### The name of the shared object file:
SOFILE = libvdr-$(PLUGIN).so

### Includes and Defines (add further entries here):
#INCLUDES += $(shell pkg-config --cflags $(LIBREPFUNC))
DEFINES += -DPLUGIN_NAME_I18N='"$(PLUGIN)"'
#LDFLAGS += $(shell pkg-config --libs $(LIBREPFUNC)) 

### The main target:
all: check_dependencies $(SOFILE) i18n


#/******************************************************************************
# * color definitions, RST=reset, CY=cyan, MG=magenta, BL=blue, (..)
# *****************************************************************************/
RST=\e[0m
CY=\e[1;36m
MG=\e[1;35m
BL=\e[1;34m
YE=\e[1;33m
RD=\e[1;31m
GN=\e[1;32m




#/******************************************************************************
# * Implicit rules
# *****************************************************************************/

%.o: %.c
ifeq ($(CXX),@g++)
	@echo -e "${CY} CXX $@${RST}"
endif
	$(CXX) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<

%.o: %.cpp
ifeq ($(CXX),@g++)
	@echo -e "${BL} CXX $@${RST}"
endif
	$(CXX) $(CXXFLAGS) -c $(DEFINES) $(INCLUDES) -o $@ $<



### Dependencies:
MAKEDEP = $(CXX) -MM -MG
DEPFILE = .dependencies
$(DEPFILE): Makefile
	@$(MAKEDEP) $(CXXFLAGS) $(DEFINES) $(INCLUDES) $(CPPSRC) > $@

-include $(DEPFILE)

### Internationalization (I18N):

PODIR     = po
I18Npo    = $(wildcard $(PODIR)/*.po)
I18Nmo    = $(addsuffix .mo, $(foreach file, $(I18Npo), $(basename $(file))))
I18Nmsgs  = $(addprefix $(DESTDIR)$(LOCDIR)/, $(addsuffix /LC_MESSAGES/vdr-$(PLUGIN).mo, $(notdir $(foreach file, $(I18Npo), $(basename $(file))))))
I18Npot   = $(PODIR)/$(PLUGIN).pot

%.mo: %.po
	@msgfmt -c -o $@ $<

$(I18Npot): $(wildcard *.c)
	@xgettext -C -cTRANSLATORS --no-wrap --no-location -k -ktr -ktrNOOP --package-name=vdr-$(PLUGIN) --package-version=$(VERSION) --msgid-bugs-address='<see README>' -o $@ `ls $^`

%.po: $(I18Npot)
	@msgmerge -U --no-wrap --no-location --backup=none -q -N $@ $<
	@touch $@

$(I18Nmsgs): $(DESTDIR)$(LOCDIR)/%/LC_MESSAGES/vdr-$(PLUGIN).mo: $(PODIR)/%.mo
	@install -D -m644 $< $@

.PHONY: i18n check_dependencies
i18n: $(I18Nmo) $(I18Npot)

install-i18n: $(I18Nmsgs)

### Targets:

$(SOFILE): $(OBJS)
ifeq ($(CXX),@g++)
	@echo -e "${GN} LINK $(SOFILE)${RST}"
endif
	$(CXX) $(CXXFLAGS) -shared $(OBJS) -o $@ $(LDFLAGS)

install-lib: $(SOFILE)
	install -D $^ $(DESTDIR)$(LIBDIR)/$^.$(APIVERSION)

install: install-lib install-i18n

dist: $(I18Npo) clean
	@-rm -rf $(TMPDIR)/$(ARCHIVE)
	@mkdir $(TMPDIR)/$(ARCHIVE)
	@cp -a $(DISTFILES) $(TMPDIR)/$(ARCHIVE)
	@tar czf $(PACKAGE).tgz -C $(TMPDIR) $(ARCHIVE)
	@-rm -rf $(TMPDIR)/$(ARCHIVE)
	@echo Distribution package created as $(PACKAGE).tgz

clean:
	@-rm -f $(SOFILE) $(SOFILE).$(APIVERSION)
	@-rm -f $(PODIR)/*.mo $(PODIR)/*.pot
	@-rm -f $(OBJS) $(DEPFILE) *.so *.tgz core* *~


#/******************************************************************************
# * dependencies, check them here and provide message to user.
# *****************************************************************************/
check_dependencies:
#ifeq ($(HAVE_LIBREPFUNC),0)
#	@echo "ERROR: not found: $(LIBREPFUNC) >= $(LIBREPFUNC_MINVERSION)"
#	exit 1
#endif
#ifeq ($(HAVE_LIBREPFUNC_MINVERSION),0)
#	@echo "ERROR: dependency $(LIBREPFUNC) older than $(LIBREPFUNC_MINVERSION)"
#	exit 1
#endif
