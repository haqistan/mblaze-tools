# Tooling for mblaze #

I make no advertisements for these scripts except: they are generally
short and do one thing.  Well...

They are my workflow on top of mblaze, which is pretty minimal.  I'm
not really happy with them, but I use them every day.

I think this says something about me but my hearing is going because
I'm old and I can't make out what the kids are saying.

Use at your own risk.  On a POSIX system.  Preferably OpenBSD.

A brief description of what these things do:

    mapply      apply our args as a command to each filename on stdin
    mbytime     obsolete
    mdecrypt    given a liste of message numbers/sequences, decrypt them
    minbox      list your inbox in threaded form
    mincall     invoke minc on all directories with new mail
    mlatest     obsolete
    mmv         given a destination folder in command line mv files on stdin
    mnewbox     show new messages in given folder
    mnewdirs    show all folders with new messages plus a count per folder
    mpane       run mnewbox in a new tmux pane and leave it there
    mrespam     mark messages on stdin as spam (false negative)
    mrm         like mmv but rm the messages on stdin
    msign       obsolete
    msummary    summarize the message on stdin, mainly useful via fdm
    munspam     mark messages on stdin as not spam (false positive)
    mupdatime   obsolete
