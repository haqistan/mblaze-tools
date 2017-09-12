#

BINDIR?=${HOME}/bin
SCRIPTS=mapply minbox mincall mmv mnewbox mnewdirs mpane mrespam mrm msign msummary munspam

all: ${SCRIPTS}

install: all
	cp ${SCRIPTS} ${BINDIR}
	ln -sf ${BINDIR}/mmv ${BINDIR}/mcp
