#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#

NODE_BIN   = node_modules/.bin

NODEJS     = node
NPM        = npm
COFFEE     = $(NODE_BIN)/coffee
DOCCO      = $(NODE_BIN)/docco
MOCHA      = $(NODE_BIN)/mocha
ISTANBUL   = $(NODE_BIN)/istanbul

SCRIPTS    = \
	lib/heterarchy.js \

DOCS       = \
	doc/index.html \
	doc/heterarchy.html \
	doc/test/heterarchy.spec.html


all: $(SCRIPTS)

framework: $(FRAMEWORK)

doc: $(DOCS)
	cp -r ./pic ./doc/

.SECONDARY:
.PHONY: test

lib/%.js: %.litcoffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@

lib/%.js: %.coffee
	@mkdir -p $(@D)
	$(COFFEE) -c -p $< > $@

lib/%.js: %.js
	@mkdir -p $(@D)
	cp -f $< $@

doc/index.html: README.md
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css  -o $(@D) $<
	mv $(@D)/README.html $@
	cp -rf docco/public $(@D)

doc/%.html: %.litcoffee
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
	cp -rf docco/public $(@D)

doc/%.html: %.coffee
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
	cp -rf docco/public $(@D)

doc/%.html: %.js
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
	cp -rf docco/public $(@D)

clean:
	rm -rf ./doc
	rm -rf ./lib
	find . -name "*~" -exec rm -f {} \;

install:
	$(NPM) install

test:
	$(MOCHA) --compilers coffee:coffee-script/register

test-coverage:
	$(MOCHA) --compilers coffee:coffee-script/register \
		 --require coffee-coverage/register-istanbul
	$(ISTANBUL) report text lcov

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /heterarchy doc/*
