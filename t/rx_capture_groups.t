#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use warnings;
use FindBin;
use Test::More 'no_plan';

require "$FindBin::RealBin/../blib/script/psort";

my @tests = (
     # rx                              expected result
    [qr/([0-9]*)-(?:[a-z]*)-([0-9]*)/, 1],
    [qr/([0-9]*)/,                     1],
    [qr/[0-9]*/,                       0],
    [qr/\Q([0-9]*)/,                   0],
    [qr/(?:[0-9]*)/,                   0],
    [qr/\([0-9]*\)/,                   0],
);

for my $test (@tests) {
    my($rx, $expected) = @$test;
    is _has_capture_groups($rx)?1:0, $expected, "_has_capture_groups($rx)";
}
