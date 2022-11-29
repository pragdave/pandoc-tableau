PARSER=$(addprefix parser/, dump.yue row_parser.yue split.yue string_scanner.yue ast.yue util.yue)
PARSER2=$(addprefix parser2/, dump.yue string_scanner.yue util.yue parse_spec.yue)

TDIR=_extensions/tableau_pdf
TPDIR=$(TDIR)/parser
TP2DIR=$(TDIR)/parser2

TPARSER=$(patsubst %.yue, $(TDIR)/%.lua, $(PARSER))
TPARSER2=$(patsubst %.yue, $(TDIR)/%.lua, $(PARSER2))

.default: build

$(TDIR)/%.lua:	src/%.yue
	yue -o $@ $<

build: tp1 tp2 $(TDIR)/tableau_pdf.lua 

tp1: $(TPDIR) $(TPARSER) 

tp2: $(TP2DIR) $(TPARSER2)

# TDIR=_extensions/tableau
# TARGETS=$(patsubst %.yue, $(TDIR)/%.lua, $(SRC))



# build:	$(TDIR) $(TARGETS)

# test:
# 	cd src && yue -e test.yua

$(TPDIR):
		mkdir -p $(TPDIR)
$(TP2DIR):
		mkdir -p $(TP2DIR)
