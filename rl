#!/usr/bin/env perl

# rl - call GNU readline w/history saving

# simplest way to add command-line editing to mb portably
# requies Term::ReadLine::Gnu be installed

use Modern::Perl;
use Getopt::Long;
use Pod::Usage;
use Scalar::Util qw(looks_like_number);
use Term::ReadLine;

package HistoryFile;

use List::Util qw(max min);

sub new { bless({file=>$_[1],@_},$_[0]) }
sub append {
	my($self,$input) = @_;
	my $fn = $self->{file};
	warn("# saving history => $fn\n") if $self->{verbose};
	my $f = IO::File->new($fn, ">>:utf8")
		or die "rl canot save $fn: $!";
	$f->print("$input\n");
	$f->close();
	return $self;
}
sub overwrite {
	my($self,$rl) = @_;
	my $fn = $self->{file};
	$rl //= $self->{rl};
	die "no rl!" unless $rl;
	my $f = IO::File->new($fn, ">:utf8")
		or die "rl cannot write $fn: $!";
	$f->print("$_\n") foreach ($rl->GetHistory());
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
	while (defined(my $line = $f->getline())) {
		$line =~ s/\s+$//;
		next unless $line;
		$rl->add_history($line);
	}
	$f->close();
	return $self;
}
sub list {
	my($self,$n,$rl) = @_;
	$rl //= $self->{rl};
	my @hist = $rl->GetHistory();
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
	my @hist = $rl->GetHistory();
	my $k = $#hist;
	$n //= 0;
	my @seq = ($n > 0)? (max(($k-$n)+1,0) .. $k):
		(($n < 0)? (0 .. min(abs($n)-1,$k)): (0 .. $k));
	@hist = splice(@hist,@seq);
	warn("# clear n=$n k=$k seq=@seq new=".scalar(@hist)."\n")
		if $self->{verbose};
	$rl->clear_history();
	$rl->add_history($_) foreach (@hist);
	return $self->overwrite();
}
sub grep {
	my($self,$pat,$rl) = @_;
	$rl //= $self->{rl};
	my @hist = $rl->GetHistory();
	warn("# grep /$pat/\n") if $self->{verbose};
	warn("$_: ".$hist[$_]."\n")
		foreach (grep { $hist[$_] =~ /$pat/ } (0 .. $#hist));
	return $self;
}

package main;
	
MAIN: {
	my($help,$no_history,$history_file,$verbose);
	Getopt::Long::Configure("bundling");
	GetOptions(
		'help|?' => \$help,
		'no-history|H' => \$no_history,
		'history|F=s' => \$history_file,
		'verbose|v+' => \$verbose,
	) or pod2usage();
	pod2usage(-verbose => 1+$verbose) if $help;
	my $prog = shift(@ARGV) || 'rl';
	my $prompt = join(" ",@ARGV) || "${prog}> ";
	my $rl = Term::ReadLine->new($prog);
	$history_file //= join("/",$ENV{HOME},".${prog}.history")
		unless $no_history;
	warn("# $prog history file: $history_file\n") if $verbose;
	my $history =
		HistoryFile->new($history_file,rl=>$rl,verbose=>$verbose)
		->load() if !$no_history && $history_file;
	my $xit = undef;
	my $input;
	do {
		$input = $rl->readline($prompt);
		if (!defined($input)) {
			$xit = 1;
		} else {
			chomp($input);
			$history->append($input) if $history && $input;
			if ($input && $input =~ /^\.h\w+(|\s+(\S.*))$/) {
				my $arg = $1;
				$arg =~ s/(^\s+|\s+$)//gs;
				my @args = split(/\s+/,$arg);
				if (!@args) {
					$history->list(10);
				} elsif (looks_like_number($args[0])) {
					$history->list(int($args[0]));
				} elsif ($args[0] eq 'clear') {
					shift(@args);
					$history->clear(@args);
				} elsif ($args[0] =~ /^\//) {
					$arg =~ s/(^\/|\/$)//gs;
					$history->grep($arg);
				} else {
					warn("rl: .history? @args\n");
				}
			} elsif ($input) {
				$xit = 0;
			} # else ignore blank lines
		}
	} while (!defined($xit));
	say $input if defined $input;
	exit($xit);
}

__END__

=pod

=head1 NAME

rl - read line with editing and history

=head1 SYNOPSIS

rl [-vH] [-F histfile] progname [prompt...]

Options:

    --help       -?        print this manual
    --verbose    -v        spew messages about loading/saving history
    --no-history -H        do not load/save history this invocation
    --history    -F file   load/save history from/to this file

=head1 DESCRIPTION

Read a line from the terminal w/command line editing and history
support.  By default the command history will go in
C<~/.progname.history>, e.g. if you invoke us like so:

    rl mb 'INBOX*> '

history will be restored/saved from/to C<~/.mb.history>.  Whatever
line we finally read is spit out on stdout.

We handle inputs that look like C<.history ...args...> ourselves
and don't print them on stdout for our caller.  A summary:

=over 4

=item * .history [number]

With no arguments lists the latest 10 entries in the history

If the number is negative, that many entries from the beginning
of the history are listed.  If the number is postive, that many
entries from recent history, and if zero the whole history
is listed to stderr.

=item * .history clear [number]

With no arguments clears all of history.  Otherwise the
interpretation of number is the same as for listing
history.

=back


=cut
