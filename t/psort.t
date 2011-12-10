#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use File::Temp qw(tempfile);

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }

    *eq_or_diff = eval { require Test::Differences; \&Test::Differences::eq_or_diff } || \&Test::More::eq;
}

my $psort = "$FindBin::RealBin/../blib/script/psort";

my @test_defs =
    (
     [undef, <<EOF, <<EOF],
c
b
a
EOF
a
b
c
EOF

     [["-e", 'm{(\d+) wallclock secs}; $1'], <<EOF, <<EOF],
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
EOF
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
EOF
     
    );

plan tests => 1 + 2 * @test_defs;

ok -x $psort, 'psort is executable';

for my $test_def (@test_defs) {
    run_psort(@$test_def);
}

sub run_psort {
    my($args, $indata, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    my($tmpfh,$tmpfile) = tempfile(UNLINK => 1, SUFFIX => ".dat")
	or die $!;
    print $tmpfh $indata;
    close $tmpfh
	or die $!;

    my @cmd = ($psort, $args ? @$args : (), $tmpfile);

    open my $fh, "-|", @cmd
	or die $!;
    my $buf;
    while(<$fh>) {
	$buf .= $_;
    }
    ok close($fh), "Failure while running '@cmd': $?";

    eq_or_diff $buf, $expected;
}

__END__
