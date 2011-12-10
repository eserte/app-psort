#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 1;

use App::psort;

my $psort = "$FindBin::RealBin/../blib/script/psort";

my($script_version) = `$psort --version` =~ m{version\s+(\S+)};

is $script_version, $App::psort::VERSION, 'Script and module version are the same';

__END__
