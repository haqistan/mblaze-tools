# Some scripts on top of mblaze that suit my workflow

BINDIR?=${HOME}/bin
SCRIPTS=mapply minbox mincall mmv mnewbox mnewdirs mpane mrespam mrm \
	msign msummary munspam mdecrypt mloop mdisplay foldercheck

all: ${SCRIPTS}

install: all
	cp ${SCRIPTS} ${BINDIR}
	ln -sf ${BINDIR}/mmv ${BINDIR}/mcp
	ln -sf ${BINDIR}/msign ${BINDIR}/mencrypt
