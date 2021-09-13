VERSION = $(shell cat VERSION)

SRCS = src/yaml_private.h \
	src/yaml.h \
	src/r_ext.h \
	src/writer.c \
	src/scanner.c \
	src/dumper.c \
	src/emitter.c \
	src/implicit.re \
	src/reader.c \
	src/parser.c \
	src/api.c \
	src/loader.c \
	src/r_ext.c \
	src/r_emit.c \
	src/r_parse.c \
	src/Makevars \
	man/as.yaml.Rd \
	man/yaml.load.Rd \
	man/write_yaml.Rd \
	man/read_yaml.Rd \
	inst/THANKS \
	inst/CHANGELOG \
	tests/RUnit.R \
	inst/tests/test_yaml_load_file.R \
	inst/tests/test_yaml_load.R \
	inst/tests/test_as_yaml.R \
	inst/tests/test_read_yaml.R \
	inst/tests/test_write_yaml.R \
	inst/tests/files/test.yml \
	inst/tests/files/merge.yml \
	DESCRIPTION \
	COPYING \
	LICENSE \
	R/yaml.load.R \
	R/zzz.R \
	R/utils.R \
	R/yaml.load_file.R \
	R/as.yaml.R \
	R/read_yaml.R \
	R/write_yaml.R \
	NAMESPACE

BUILD_SRCS = build/yaml/src/yaml_private.h \
	build/yaml/src/yaml.h \
	build/yaml/src/r_ext.h \
	build/yaml/src/writer.c \
	build/yaml/src/scanner.c \
	build/yaml/src/dumper.c \
	build/yaml/src/emitter.c \
	build/yaml/src/implicit.c \
	build/yaml/src/reader.c \
	build/yaml/src/parser.c \
	build/yaml/src/api.c \
	build/yaml/src/loader.c \
	build/yaml/src/r_ext.c \
	build/yaml/src/r_emit.c \
	build/yaml/src/r_parse.c \
	build/yaml/src/Makevars \
	build/yaml/man/as.yaml.Rd \
	build/yaml/man/yaml.load.Rd \
	build/yaml/man/write_yaml.Rd \
	build/yaml/man/read_yaml.Rd \
	build/yaml/inst/THANKS \
	build/yaml/inst/CHANGELOG \
	build/yaml/inst/implicit.re \
	build/yaml/inst/tests/test_yaml_load_file.R \
	build/yaml/inst/tests/test_yaml_load.R \
	build/yaml/inst/tests/test_as_yaml.R \
	build/yaml/inst/tests/test_read_yaml.R \
	build/yaml/inst/tests/test_write_yaml.R \
	build/yaml/inst/tests/files/test.yml \
	build/yaml/inst/tests/files/merge.yml \
	build/yaml/tests/RUnit.R \
	build/yaml/DESCRIPTION \
	build/yaml/COPYING \
	build/yaml/LICENSE \
	build/yaml/R/yaml.load.R \
	build/yaml/R/zzz.R \
	build/yaml/R/utils.R \
	build/yaml/R/yaml.load_file.R \
	build/yaml/R/as.yaml.R \
	build/yaml/R/read_yaml.R \
	build/yaml/R/write_yaml.R \
	build/yaml/NAMESPACE

ifdef DEBUG
  CFLAGS += -DDEBUG
endif

test_code = "library(RUnit); library(yaml, lib.loc = 'build/lib'); source('build/yaml/tests/RUnit.R')"

all: test

check: build/yaml
	R CMD check -o `mktemp -d` build/yaml

gct-check: build/yaml
	R CMD check --use-gct -o `mktemp -d` build/yaml

valgrind-check: build/yaml
	R CMD check --use-valgrind -o `mktemp -d` build/yaml

test: build/lib/yaml
	R --vanilla -e $(test_code)

gct-test: build/lib/yaml
	R --vanilla -e "library(RUnit); library(yaml, lib.loc = 'build/lib'); options(yaml.verbose = TRUE); gctorture(TRUE); source('build/yaml/tests/RUnit.R'); gctorture(FALSE)"

gdb-test: build/lib/yaml
	R -d gdb --vanilla -e $(test_code)

valgrind-test: build/lib/yaml
	R -d "valgrind --leak-check=full" -e $(test_code)

check-changelog: VERSION inst/CHANGELOG
	@if ! grep -q "$(VERSION)" inst/CHANGELOG; then echo -e "\033[31mWARNING: CHANGELOG has not been updated\033[0m"; fi

check-description: VERSION DESCRIPTION
	@if ! grep -q "$(VERSION)" DESCRIPTION; then echo -e "\033[31mWARNING: DESCRIPTION has not been updated\033[0m"; fi

tarball: yaml_$(VERSION).tar.gz check-changelog check-description
	check_dir=`mktemp -d`; echo Check directory: $$check_dir; R CMD check --as-cran -o "$$check_dir" yaml_$(VERSION).tar.gz

check-revdeps: yaml_$(VERSION).tar.gz check-changelog check-description
	mkdir -p check
	cp yaml_$(VERSION).tar.gz check
	R --vanilla -e "options(repos = 'https://cloud.r-project.org'); checkResult <- tools::check_packages_in_dir('check', reverse = TRUE); save(checkResult, file='check/checkResult.RData')"

yaml_$(VERSION).tar.gz: build/yaml
	R CMD build build/yaml

src/implicit.c: src/implicit.re
	cd $(dir $<); re2c -o $(notdir $@) --no-generation-date $(notdir $<)

build/yaml: $(BUILD_SRCS)

build/lib:
	mkdir -p $@

build/lib/yaml: build/lib build/yaml
	R CMD INSTALL -l build/lib build/yaml


build/yaml/inst/implicit.re: src/implicit.re
	mkdir -p $(dir $@)
	cp $< $@

build/yaml/%: %
	mkdir -p $(dir $@)
	cp $< $@

clean:
	rm -fr yaml_*.tar.gz build

.PHONY: all check gct-check test gct-test gdb-test clean valgrind-test check-changelog check-description tarball
