#

BINDIR?=${HOME}/bin
SCRIPTS=mapply minbox mmv mnewdirs mpane mrespam msign msummary munspam

all: ${SCRIPTS}

install: all
	cp ${SCRIPTS} ${BINDIR}
