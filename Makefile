# Some scripts on top of mblaze that suit my workflow

BINDIR?=${HOME}/bin
SCRIPTS=mapply minbox mincall mnewbox mnewdirs mpane mrespam mrm \
	msign msummary munspam mdecrypt mb mdisplay foldercheck mailcheck rl

all: ${SCRIPTS}

install: all
	cp ${SCRIPTS} ${BINDIR}
	ln -sf ${BINDIR}/msign ${BINDIR}/mencrypt
