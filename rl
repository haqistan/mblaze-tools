#!/usr/bin/env perl

# rl - call GNU readline w/history saving

# simplest way to add command-line editing to mb portably
# requies Term::ReadLine::Gnu be installed

use Modern::Perl;
use Getopt::Long;
use Pod::Usage;
use Term::ReadLine;

MAIN: {
	my($no_history,$history_file,$verbose);
	Getopt::Long::Configure("bundling");
	GetOptions(
		'no-history|H' => \$no_history,
		'history|F=s' => \$history_file,
		'verbose|v' => \$verbose,
	) or pod2usage();
	my $prog = shift(@ARGV) || 'rl';
	my $prompt = join(" ",@ARGV) || '> ';
	my $rl = Term::ReadLine->new($prog);
	$history_file //= join("/",$ENV{HOME},".${prog}.history")
		unless $no_history;
	if ($history_file && -f $history_file) {
		warn("# loading history: $history_file\n") if $verbose;
		my $f = IO::File->new($history_file,"<:utf8")
			or die "$prog/rl history file $history_file: $!\n";
		while (defined(my $line = $f->getline())) {
			$line =~ s/\s+$//;
			next unless $line;
			$rl->add_history($line);
		}
		$f->close();
	}
	my $input = $rl->readline($prompt);
	if (!defined($input)) {
		exit(1);
	} else {
		chomp($input);
		if ($history_file) {
			warn("# saving history => $history_file\n") if $verbose;
			my $f = IO::File->new($history_file, ">>:utf8")
				or die "$prog/rl canot save $history_file: $!";
			$f->print("$input\n");
			$f->close();
		}
		say $input;
		exit(0);
	}
}

__END__

=pod

=head1 NAME

rl - read line with editing and history

=head1 SYNOPSIS

rl [-vH] [-F histfile] progname [prompt...]

Options:

    --verbose    -v        spew messages about loading/saving history
    --no-history -H        do not load/save history this invocation
    --history    -F file   load/save history from/to this file

Read a line from the terminal w/command line editing and history
support.

=cut
