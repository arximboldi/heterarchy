#
#  File:       makefile
#  Author:     Juan Pedro Bolívar Puente <raskolnikov@es.gnu.org>
#

NODE_BIN      = node_modules/.bin

NODEJS        = node
NPM           = npm
COFFEE        = $(NODE_BIN)/coffee
DOCCO         = $(NODE_BIN)/docco
MOCHA         = $(NODE_BIN)/mocha
MOCHA_PHANTOM = $(NODE_BIN)/mocha-phantomjs
ISTANBUL      = $(NODE_BIN)/istanbul
COFFEELINT    = $(NODE_BIN)/coffeelint
PHANTOM_JS    = `which phantomjs`

SCRIPTS       = \
	lib/heterarchy.js \

DOCS          = \
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
	$(COFFEE) --compile --print $< > $@

lib/%.js: %.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile --print $< > $@

lib/%.js: %.js
	@mkdir -p $(@D)
	cp -f $< $@

doc/index.html: README.md
	@mkdir -p $(@D)
	$(DOCCO) -t docco/docco.jst -c docco/docco.css -o $(@D) $<
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

test: all
	$(MOCHA) --compilers coffee:coffee-script/register `find test -name *.coffee`
	@$(COFFEE) --compile test/heterarchy.spec.coffee
	@# if phantomjs is actually installed (not just as a node module) use that
	@# because there is a bug on macOS with the node module
	@if [[ $(PHANTOM_JS) = "" ]]; then \
		echo "$(MOCHA_PHANTOM) test/heterarchy.browser.html"; \
		$(MOCHA_PHANTOM) test/heterarchy.browser.html; \
	else \
		echo "$(MOCHA_PHANTOM) -p $(PHANTOM_JS) test/heterarchy.browser.html"; \
		$(MOCHA_PHANTOM) -p $(PHANTOM_JS) test/heterarchy.browser.html; \
	fi

lint:
	$(COFFEELINT) --literate heterarchy.litcoffee
	$(COFFEELINT) test/heterarchy.spec.coffee

test-coverage: all
	$(MOCHA) --compilers coffee:coffee-script/register \
		 --require coffee-coverage/register-istanbul \
		 `find test -name *.coffee`
	$(ISTANBUL) report text lcov

travis: lint test-coverage

upload-doc: doc
	ncftpput -R -m -u u48595320 sinusoid.es /heterarchy doc/*
