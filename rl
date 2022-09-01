#!/usr/bin/env perl

# rl - call GNU readline w/history saving

# simplest way to add command-line editing to mb portably
# OpenBSD deps: p5-Modern-Perl, p5-Pod-Usage, p5-Term-ReadLine-Gnu

use Modern::Perl;
use Cwd;
use Getopt::Long;
use Pod::Usage;
use Scalar::Util qw(looks_like_number);
use Term::ReadLine;

package HistoryFile;

use List::Util qw(max min);

sub new { bless({file=>$_[1],lines => [],@_},$_[0]) }
sub trim {
	my($self,@hist) = @_;
	@hist = @{$self->{lines}} unless @hist;
	my $maxh = $self->{max_history} // 0;
	shift(@hist) while ($maxh && 0+@hist >= $maxh);
	return @hist;
}
sub append {
	my($self,$input) = @_;
	my $fn = $self->{file};
	my @hist = $self->trim();
	my $max = $self->{max_history} // 0;
	warn("# saving history => $fn\n") if $self->{verbose};
	warn("# new input: |$input|, previous history ".
	     scalar(@hist).": ".join(", ",@hist)."\n")
		if $self->{verbose} > 1;
	push(@hist,$input);
	my $f = IO::File->new("${fn}.tmp", ">:utf8")
		or die "rl canot save ${fn}.tmp: $!";
	$f->print("$_\n") foreach @hist;
	$f->close();
	die "unlink ${fn}.bak: $!"
		if -f "${fn}.bak" && !unlink("${fn}.bak");
	die "rename ${fn} ${fn}.bak: $!"
		unless (!-f $fn) || rename($fn,"${fn}.bak");
	die "rename ${fn}.tmp ${fn}: $!"
		unless rename("${fn}.tmp",$fn);
	return $self;
}
sub overwrite {
	my($self,$rl) = @_;
	my $fn = $self->{file};
	$rl //= $self->{rl};
	die "no rl!" unless $rl;
	my $f = IO::File->new($fn, ">:utf8")
		or die "rl cannot write $fn: $!";
	$f->print("$_\n") foreach ($self->trim());
	$f->close();
	return $self;
}
sub load {
	my($self,$rl) = @_;
	my $history_file = $self->{file};
	$rl //= $self->{rl};
	warn("# loading history: $history_file\n") if $self->{verbose};
	if (!(-f $history_file)) {
		warn("# history empty - skipped\n") if $self->{verbose};
		return $self;
	}
	my $f = IO::File->new($history_file,"<:utf8")
		or die "rl history file $history_file: $!\n";
	my @lines;
	while (defined(my $line = $f->getline())) {
		$line =~ s/\s+$//;
		next unless $line;
		push(@lines,$line);
	}
	$f->close();
	@lines = $self->trim(@lines);
	$self->{lines} = [@lines];
	$rl->clear_history();
	$rl->add_history($_) foreach @lines;
	return $self;
}
sub list {
	my($self,$n,$rl) = @_;
	$rl //= $self->{rl};
	my @hist = @{$self->{lines}};
	my $k = $#hist;
	my @seq = ($n > 0)? (max(($k-$n)+1,0) .. $k):
		(($n < 0)? (0 .. min(abs($n)-1,$k)): (0 .. $k));
	warn("# list n=$n k=$k seq=@seq\n") if $self->{verbose};
	warn("$_: ".$hist[$_]."\n") foreach (@seq);
	return $self;
}
sub clear {
	my($self,$n,$rl) = @_;
	$rl //= $self->{rl};
	my @hist = @{$self->{lines}};
	my $k = $#hist;
	$n //= 0;
	my @seq = ($n > 0)? (max(($k-$n)+1,0) .. $k):
		(($n < 0)? (0 .. min(abs($n)-1,$k)): (0 .. $k));
	@hist = splice(@hist,@seq);
	$self->{lines} = [@hist];
	warn("# clear n=$n k=$k seq=@seq new=".scalar(@hist)."\n")
		if $self->{verbose};
	$rl->clear_history();
	$rl->add_history($_) foreach (@hist);
	return $self->overwrite();
}
sub grep {
	my($self,$pat,$rl) = @_;
	$rl //= $self->{rl};
	my @hist = @{$self->{lines}};
	warn("# grep /$pat/\n") if $self->{verbose};
	warn("$_: ".$hist[$_]."\n")
		foreach (grep { $hist[$_] =~ /$pat/ } (0 .. $#hist));
	return $self;
}

package main;

our %STYLES = (
	bold => 'so,se,se,se',
	underline => 'us,ue,ue,ue',
	plain => '',
);

MAIN: {
	my($help,$no_history,$history_file,$verbose,$style,
	   $max_history,@completes,$chdir,$preput);
	my $xit = undef;
	my $input;
	my $here = getcwd();
	$SIG{ALRM} = sub { warn(" ALARM!\n"); $xit = 200; };
	$SIG{QUIT} = sub { warn(" QUIT!\n"); $xit = 201; };
	$SIG{INFO} = sub { exit(202); } if exists $SIG{INFO};
	Getopt::Long::Configure("bundling");
	GetOptions(
		'help|?' => \$help,
		'no-history|H' => \$no_history,
		'history|F=s' => \$history_file,
		'max-history|X=i' => \$max_history,
		'style|S=s' => \$style,
		'complete|C=s' => \@completes,
		'chdir|D=s' => \$chdir,
		'verbose|v+' => \$verbose,
		'preput|P=s' => \$preput,
	) or pod2usage();
	$verbose //= 0;
	pod2usage(-verbose => 1+$verbose) if $help;
	$style //= 'plain';
	pod2usage(-msg => "invalid style: $style")
		unless exists $STYLES{$style};
	die "no such dir: $chdir\n"
		if $chdir && ! -d $chdir;
	my $prog = shift(@ARGV) || 'rl';
	my $prompt = join(" ",@ARGV) || "> ";
	$prompt = "[${prog}] ${prompt}" if $prog ne 'rl';
	# set process name for ps(1)
	my $procname = "rl:${prog}";
	$procname .= " ${prompt}" if $verbose;
	$0 = $procname;
	my $rl = Term::ReadLine->new($prog);
	# style
	my $ornaments = $STYLES{$style};
	$rl->ornaments($ornaments);
	# history
	$history_file //= join("/",$ENV{HOME},".${prog}.history")
		unless $no_history;
	warn("# $prog history file: $history_file\n")
		if $history_file && $verbose;
	my $history =
		HistoryFile->new(
			$history_file,rl=>$rl,verbose=>$verbose,
			max_history=>$max_history,
		)->load() if !$no_history && $history_file;
	# completion: try @completes first and fall back to filenames
	if (@completes) {
		my $attribs = $rl->Attribs;
		$attribs->{attempted_completion_function} = sub {
			my($text,$line,$start,$end) = @_;
			if (substr($line,0,$start) =~ /^\s*$/) {
				return $rl->completion_matches(
					$text,
					$attribs->{list_completion_function})
			} else {
				return ();
			}
		};
		@completes = map { split(/,/,$_) } @completes;
		$attribs->{completion_word} = \@completes;
	}
	do {
	      INPUT:
		chdir($chdir) if $chdir;
		$xit = undef;
		$input = $rl->readline($prompt,$preput);
		$preput = '';
		chdir($here) if $chdir;
		if (!defined($input)) {
			$xit //= 1;
		} else {
			chomp($input);
			goto INPUT unless $input;
			$history->append($input) if $history;
			if ($input !~ /^\.h\w+(|\s+(\S.*))$/) {
				$xit = 0;
			} else {
				my $arg = $1;
				$arg =~ s/(^\s+|\s+$)//gs;
				my @args = split(/\s+/,$arg);
				if (!@args) {
					$history->list(10);
				} elsif (looks_like_number($args[0])) {
					$history->list(int($args[0]));
				} elsif ($args[0] eq 'clear') {
					shift(@args);
					$history->clear(shift(@args));
				} elsif ($args[0] =~ /^\//) {
					$arg =~ s/(^\/|\/$)//gs;
					$history->grep($arg);
				} else {
					warn("rl: .history? @args\n");
				}
			}
		}
	} while (!defined($xit));
	if (defined($input)) {
		$input =~ s/^\s+//;
		$input =~ s/\/+$//;
		say $input;
	}
	exit($xit);
}

__END__

=pod

=head1 NAME

rl - read a line from tty with editing and history

=head1 SYNOPSIS

rl [-vH] [-F histfile] [-X maxhist] [-S style] [-C word[,...]] [-D dir] progname [prompt...]

Options:

    --help       -?        print this manual
    --verbose    -v        spew messages about loading/saving history
    --no-history -H        do not load/save history this invocation
    --history    -F file   load/save history from/to this file
    --max-history -X int   maximum history size in lines (def: none)
    --style      -S style  one of: bold, underline or plain (def: plain)
    --complete   -C word   add word to completion list (more than once)
    --chdir       -D dir   chdir to dir when reading input (for fn complete)

=head1 DESCRIPTION
	

Read a line from the terminal w/command line editing, completion and
history support.  By default the command history will go in
C<~/.progname.history>, e.g. if you invoke us like so:

    rl prog 'INBOX*> '

history will be restored/saved from/to C<~/.prog.history>.  Whatever
line we finally read is spit out on stdout.

If no C<--complete> options are given filename completion will be done
by default; you can control which directory to complete relative to
with the C<--chdir> option.  If any C<--complete> options are given,
the total set of words (after splitting on comma) will be treated as
commands that should be the initial word of any line.  Words beyond
the first will use filename completion, which will also be used as the
fall-back if no completion word matches the initial input.

Command-line Options:

=over 4

=item * C<--help>, C<-?>

Print some part of this manual.

=item * C<--verbose>, C<-v>

Combined with C<--help> prints the whole manual.
Otherwise, enables debug output on stderr.

=item * C<-no-history>, C<-H>

Do not load/save history.

=item *  C<--history=file>, C<-F file> 

Load/save history from/to this file.

=item * C<--max-history=int>, <-X int>

Maximum history size in lines (def: none)

=item * C<--style=style>,  C<-S style>

Style to apply to the prompt.  One of: bold, underline or plain (def:
plain).

=item * C<--complete=word[,word...]>, C<-C word[,word..]>

Add word(s) to completion list.  Can be given more than once and each
option's value is also treated as a comma-separated list, so C<-C one
-C two> and C<-C one,two> are the same.

=item * C<--chdir=dir>, C<-D dir>

Chdir to dir when reading input, so that filename completion has the
deswired effect.

=back

We handle input lines that start with a period ourselves.
They look like C<.command [args...]>.

There is currently one internal command, C<.history>.

=over 4

=item * .history [number]

With no arguments lists the latest 10 entries in the history

If the number is negative, that many entries from the beginning
of the history are listed.  If the number is postive, that many
entries from recent history, and if zero the whole history
is listed to stderr.

=item * .history /pattern.../

Search the history for the given regexp and print matching entries to
stderr.

=item * .history clear [number]

With no arguments clears all of history.  Otherwise the
interpretation of number is the same as for listing
history.

=back


=cut
