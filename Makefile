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

DRIVER=tableau_pre.yue

ASSETS=assets/tableau_pre/tableau.css

TDIR=_extensions/tableau_pre
TDIR_PARSER=$(TDIR)/parser
TDIR_ASSETS=$(TDIR)/assets
TASSETS=$(TDIR_ASSETS)/tableau.css

TDIRS=$(TDIR) $(TDIR_PARSER) $(TDIR_ASSETS)

TPARSER=$(call targets_for, $(PARSER) $(DRIVER))

$(TDIR)/%.lua:	src/%.yue
	yue -o $@ $<


.default: build

build: $(TDIRS) $(TASSETS) $(TPARSER)

$(TASSETS): $(ASSETS)
	cp $(ASSETS) $(TASSETS)

$(TDIRS):
		mkdir -p $@

# $(TDIR_PARSER):
# 		mkdir -p $(TDIR_PARSER)
