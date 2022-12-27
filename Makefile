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
	yue -o $@ $<


.default: build

build: $(TDIRS) $(TASSETS) $(TPARSER)

$(TASSETS): $(ASSETS)
	cp $(ASSETS) $(TASSETS)

$(TDIRS):
		mkdir -p $@

.PHONY: doc
doc: tableau.html

tableau.html: tableau.qmd build
	quarto render tableau.qmd

tableau.qmd: tableau.docco util/sbs.lua
	lua util/sbs.lua <tableau.docco >tableau.qmd


# $(TDIR_PARSER):
# 		mkdir -p $(TDIR_PARSER)
