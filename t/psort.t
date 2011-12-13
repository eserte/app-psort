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

    *eq_or_diff = eval { require Test::Differences; \&Test::Differences::eq_or_diff } || \&Test::More::is;
}

my $psort = "$FindBin::RealBin/../blib/script/psort";

my @test_defs =
    (# options
     #       in
     #              out (expected)
     #                     --check(able)
     #                        in is unsorted
     [undef, <<EOF, <<EOF, 1, 1],
c
b
a
EOF
a
b
c
EOF

     [undef, "", "", 1, 0],

     [undef, "\n", "\n", 1, 0],

     [undef, "one line", "one line", 1, 0],

     [undef, "one line\n", "one line\n", 1, 0],

     [["-r"], <<EOF, <<EOF, 1, 0],
c
b
a
EOF
c
b
a
EOF

     [["-f"], <<EOF, <<EOF, 1, 1],
C
b
A
EOF
A
b
C
EOF

     [["-bf"], <<EOF, <<EOF, 1, 1],
 C
  b
A
EOF
A
  b
 C
EOF

     [["-n"], <<EOF, <<EOF, 1, 1],
111
22
3
EOF
3
22
111
EOF

     [["-n", "-r"], <<EOF, <<EOF, 1, 0],
111
22
3
EOF
111
22
3
EOF

     [['-N', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     # same like -N -f, but manually use'ing the module and defining
     # the compare function
     [['-MSort::Naturally=ncmp', '-C', 'ncmp($a, $b)', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     [['-N', '-r'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
EOF
foo13a
foo12z
foo12a
foo12
foolio
fooa
foo
14
9x
EOF

     [["-V"], <<EOF, <<EOF, 1, 1],
1.0
2.3.0
1.1.5.1
2.3.1
20
10.0
EOF
1.0
1.1.5.1
2.3.0
2.3.1
10.0
20
EOF

     [["-Vr"], <<EOF, <<EOF, 1, 1],
1.0
2.3.0
1.1.5.1
2.3.1
20
10.0
EOF
20
10.0
2.3.1
2.3.0
1.1.5.1
1.0
EOF

     [["-e", 'm{(\d+) wallclock secs}; $1'], <<EOF, <<EOF, 1, 1],
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
EOF
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
EOF

     [["-C", '$a cmp $b'], <<EOF, <<EOF, 1, 1],
c
b
a
EOF
a
b
c
EOF

     [["-v"], "", qr{^psort version \d+\.\d+(?:_\d+)?$}, 0, undef],

    );

my @erroneous_test_defs =
    (
     [["--invalid-option"], "", qr{usage}],
     [["--field-function", 'perl compile error'], '', qr{Cannot compile}],
     [["--compare-function", 'perl compile error'], '', qr{Cannot compile}],
    );

plan tests => 1 + 4 * @test_defs + 2 * @erroneous_test_defs;

ok -x $psort, 'psort is executable';

for my $test_def (@test_defs) {
    run_psort(@$test_def);
}

for my $test_def (@erroneous_test_defs) {
    run_psort_erroneous(@$test_def);
}

sub _run_psort {
    my($expect_error, $args, $indata, $expected, $checkable, $unsorted_in) = @_;
    $args = [] if !$args;

    my($tmpfh,$tmpfile) = tempfile(UNLINK => 1, SUFFIX => ".dat")
	or die $!;
    print $tmpfh $indata;
    close $tmpfh
	or die $!;

    my @sort_cmd  = ($psort, @$args, $tmpfile);

    my $buf = ''; # empty file = empty string!
    my $cmd_res;

 SKIP: {
	if ($expect_error) {
	    skip "Can't run stderr tests without IPC::Run", 2
		if !eval { require IPC::Run; 1 };

	    $cmd_res = IPC::Run::run(\@sort_cmd, "2>", \$buf);
	} else {
	    my $fh;
	    if ($] < 5.008) {
		open $fh, "-|" or exec @sort_cmd;
	    } else {
		open $fh, "-|", @sort_cmd
		    or die $!;
	    }
	    while(<$fh>) {
		$buf .= $_;
	    }
	    $cmd_res = close $fh;
	}

	if ($expect_error) {
	    ok !$cmd_res, 'Expected failure'
		or diag "While running '@sort_cmd'";
	} else {
	    ok $cmd_res, 'Expected success'
		or diag "While running '@sort_cmd': $?";
	}

	my $testlabel = !defined $args ? '<no args>' : "args: <@$args>";
	if (ref $expected eq 'Regexp') {
	    like $buf, $expected, $testlabel;
	} else {
	    eq_or_diff $buf, $expected, $testlabel;
	}

	if (!$expect_error) {
	SKIP: {
		skip "This test case is not checkable", 2
		    if !$checkable;

		# Check input data
		{
		    my @check_args = (@$args, (rand(2) < 1 ? '--check' : '-c'));
		    my @check_cmd = ($psort, @check_args, $tmpfile);
		    system @check_cmd;
		    my $ret = $?>>8;
		    is $ret, $unsorted_in, "Check command with args <@check_args> returned $ret (in data)";
		}

		# Check sorted data
		{
		    my($tmpsortfh,$tmpsortfile) = tempfile(UNLINK => 1, SUFFIX => '.dat')
			or die $!;
		    print $tmpsortfh $buf;
		    close $tmpsortfh
			or die $!;

		    my @check_args = (@$args, (rand(2) < 1 ? '--check' : '-c'));
		    my @check_cmd = ($psort, @check_args, $tmpsortfile);
		    system @check_cmd;
		    is $?, 0, "Check command with args <@check_args> returned $? (sorted data)";

		    unlink $tmpsortfile;
		}
	    }
	}
    }

    unlink $tmpfile;
}

sub run_psort {
    my($args, $indata, $expected, $checkable, $unsorted_in) = @_;
    _run_psort(0, $args, $indata, $expected, $checkable, $unsorted_in);
}

sub run_psort_erroneous {
    my($args, $indata, $expected) = @_;
    _run_psort(1, $args, $indata, $expected);
}

__END__
