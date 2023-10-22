YUE_CMD=$(shell luarocks show yue | sed -nf find_path.sed)

targets_for = $(patsubst %.yue, $(TDIR)/%.lua, $1)
PARSER=$(addprefix parser/, \
	ast.yue \
	parse_data_row.yue \
	parse_formats.yue \
	parse_layout_row.yue \
	parse_selector.yue \
	string_scanner.yue \
	util.yue \
	)
REST=iterate_selector.yue virtual_table.yue tableau_pre.yue
  

ASSETS=assets/tableau_pre/tableau.css

TDIR=_extensions/tableau_pre
TDIR_PARSER=$(TDIR)/parser
TDIR_ASSETS=$(TDIR)/assets
TASSETS=$(TDIR_ASSETS)/tableau.css

TDIRS=$(TDIR) $(TDIR_PARSER) $(TDIR_ASSETS)

TPARSER=$(call targets_for, $(PARSER) $(REST))

$(TDIR)/%.lua:	src/%.yue
	$(YUE_CMD) -o $@ $<


.default: build

build: $(TDIRS) $(TASSETS) $(TPARSER)

$(TASSETS): $(ASSETS)
	cp $(ASSETS) $(TASSETS)

$(TDIRS):
		mkdir -p $@

############################################# doc

.PHONY: doc
doc: docs/tableau-guide.html

docs/tableau-guide.html: docs/tableau-guide.qmd build
	quarto render docs/tableau-guide.qmd

docs/tableau-guide.qmd: docs/tableau-guide.docco util/sbs.lua
	lua util/sbs.lua <docs/tableau-guide.docco >docs/tableau-guide.qmd


# $(TDIR_PARSER):
# 		mkdir -p $(TDIR_PARSER)
