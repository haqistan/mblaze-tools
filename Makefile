#

BINDIR?=${HOME}/bin
SCRIPTS=mapply minbox mincall mmv mnewbox mnewdirs mpane mrespam msign msummary munspam

all: ${SCRIPTS}

install: all
	cp ${SCRIPTS} ${BINDIR}
