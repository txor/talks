#!/usr/bin/env perl
#
# Author: Txor <txorlings@gmail.com>
#

use strict;
use warnings;
use MIME::Base64;
use utf8;

binmode STDOUT, ":utf8";

# Check program agruments
die "Wrong number of arguments" unless $ARGV[0];
die "Can't read $ARGV[0]" unless -r $ARGV[0];

# Read the file
open FILE, $ARGV[0] or die $!;
my @lines = <FILE>;
close FILE;

# Process the log text
my @operations;
gatherData(\@operations, \@lines);
prettyPrinting(\@operations);

# Subroutines
sub gatherData {

	my ($opsRef, $linesRef) = @_;

	my $dateRegex = qr{\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\.\d{3}};
	my $typeRegex = qr{(?:Request|Response)};

	my $op;

	foreach (@$linesRef) {

		next unless /(?<date>$dateRegex).*(?<type>$typeRegex)/;
		my $type = $+{type};
		my $date = $+{date};

		my $params;
		$$params{$1} = decode_base64($2) while (/(\w+)=([^&]+)&/g);

		if (exists $$params{'ID_OPER'}) {
			$op = {};
			$$op{'ID'} = $$params{'ID_OPER'};
		}
		$$op{$type} = $params;
		$$op{"${type}Date"} = $date;
		push @$opsRef, $op unless exists $$params{'ID_OPER'};
	}
}

sub prettyPrinting {

	my ($opRef) = @_;

	my $num = 0;

	foreach (@$opRef) {

		my $id = $$_{'ID'};
		my $reqDate = $$_{'RequestDate'};
		my $req = $$_{'Request'};
		my $resDate = $$_{'ResponseDate'};
		my $res = $$_{'Response'};

		print  "╒═OPERATION $num" . "═" x 67 . "\n";
		print  "│  $id\n";
		print  "│  ┌{REQUEST at $reqDate}" . "─" x 40 . "\n";
		printf "│  │ %-20s %-20s\n", $_, $req->{$_}
		  foreach (sort keys %$req);
		print  "│  ├{RESPONSE at $resDate}" . "─" x 39 . "\n";
		printf "│  │ %-20s %-20s\n", $_, $res->{$_}
		  foreach (sort keys %$res);
		print  "└──┴" . "─" x 76 . "\n";
	
		$num++;
	}
}
