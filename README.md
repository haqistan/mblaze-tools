# Tooling for mblaze #

I make no advertisements for these scripts except: they are generally
short and do one thing.  Well...

They are my workflow on top of mblaze(7), which is pretty minimal.  I'm
not really happy with them, but I use them every day.  The basic idea
is to use tmux(1) as my UI "toolkit", since it is easy to integrate
with on the command line.  Several scripts do things with tmux, either
creating windows/panes or reading/setting the main cutbuffer.

You should read mblaze(7) and the rest of the mblaze man pages if you
want to understand what is going on here.  These scripts augment and
extend what mblaze does to suit my own workflow.  YMMV.

We pile on with mblaze and store any config information in
~/.mblaze/profile in the form of text that looks like email headers.
Things you can set there:

* MaildirBase: the base directory of your maildir tree
* Inbox: the path to your main in-box

Use at your own risk.  On a POSIX system.  Preferably OpenBSD.  I
store my maildir tree under ~/mail, and start this mess from inside of
tmux by running "mpane -n" to see new messages in my in-box.

A brief description of what these things do:

    mapply      apply our args as a command to each filename on stdin
    mdecrypt    given a liste of message numbers/sequences, decrypt them
    mdisplay    display a msgno in the tmux cut-buffer in another tmux window
    mencrypt    encrypt an outbound message using gnupg (not working)
    minbox      list your inbox in threaded form
    mincall     invoke minc on all directories with new mail
    mloop       thin command-line loop to interact with your mail
    mmv         given a destination folder in command line mv files on stdin
    mnewbox     show new messages in given folder
    mnewdirs    show all folders with new messages plus a count per folder
    mpane       run "mnewbox; mloop" in a new tmux pane
    mrespam     mark messages on stdin as spam (false negative)
    mrm         like mmv but rm the messages on stdin
    msign       sign a message using gnupg (not working)
    msummary    summarize the message on stdin, mainly useful via fdm
    munspam     mark messages on stdin as not spam (false positive)
