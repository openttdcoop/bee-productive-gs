# Busy Bee Makefile
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License along
#     with this program; if not, write to the Free Software Foundation, Inc.,
#     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
PROJECT_NAME = BusyBee

SOURCES = *.nut
VERSION_NUT = version.nut
LANGFILES = lang/*.txt
DOCS = license.txt readme.txt
BANANAS_INI = bananas.ini

MUSA = musa.py

VERSION_INFO := "$(shell ./findversion.sh)"
REPO_VERSION := $(shell echo ${VERSION_INFO} | cut -f2)
REPO_TAG := $(shell echo ${VERSION_INFO} | cut -f5)
REPO_DATE := $(shell echo ${VERSION_INFO} | cut -f7)

DISPLAY_NAME := $(PROJECT_NAME) $(REPO_TAG)
BUNDLE_NAME := $(PROJECT_NAME)
BUNDLE_FILENAME = $(shell echo "$(DISPLAY_NAME)" | sed 's/ /-/g')

BUNDLE_DIR = bundle

.PHONY: all bananas bundle clean

all: bundle

clean:
	echo "[CLEAN]"
	$(_V) rm -rf $(BUNDLE_DIR)

bundle: $(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar

$(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar: $(SOURCES) $(LANGFILES) $(DOCS)
	echo "[Bundle] $@"
	python3 check_lang_compatibility.py lang/english.txt info.nut
	rm -rf "$(BUNDLE_DIR)"
	mkdir -p "$(BUNDLE_DIR)/$(BUNDLE_FILENAME)/lang"
	cp $(SOURCES) $(DOCS) "$(BUNDLE_DIR)/$(BUNDLE_FILENAME)"
	cp $(LANGFILES) "$(BUNDLE_DIR)/$(BUNDLE_FILENAME)/lang"
	sed -e 's/^PROGRAM_VERSION.*/PROGRAM_VERSION <- $(REPO_VERSION);/' \
	    -e 's/^PROGRAM_DATE.*/PROGRAM_DATE <- "$(REPO_DATE)";/' \
	    -e 's/^PROGRAM_NAME.*/PROGRAM_NAME <- "$(DISPLAY_NAME)";/' < info.nut > "$(BUNDLE_DIR)/$(BUNDLE_FILENAME)/info.nut"
	cd $(BUNDLE_DIR); tar -cf "$(BUNDLE_FILENAME).tar" "$(BUNDLE_FILENAME)"

bundle_zip bundle_src: $(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar.zip
$(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar.zip: $(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar
	echo "[BUNDLE] $@"
	cd $(BUNDLE_DIR)
	zip -9rq $@ $<

bananas: bundle
	echo "[BaNaNaS]"
	sed -e 's/^version *=.*/version = $(REPO_TAG)/' $(BANANAS_INI) > "$(BUNDLE_DIR)/$(BANANAS_INI)"
	$(MUSA) -r -x license.txt -c $(BUNDLE_DIR)/$(BANANAS_INI) "$(BUNDLE_DIR)/$(BUNDLE_FILENAME)"

