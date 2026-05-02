#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use IPC::Run qw(run)";
if ($@) {
    plan skip_all => "IPC::Run not installed";
}

plan tests => 2;

my $out;
# Test 1: Default behavior
run([$^X, '-e', 'print "a\n"'], \undef, \$out);

# On older IPC::Run versions, $out would be "a\n" on Win32 due to auto-translation.
# On 20260402.0, $out is likely "a\r\n" because binmode=1 is now the default.

if ($^O eq 'MSWin32') {
    is($out, "a\r\n", "Default IPC::Run on Win32 now preserves CRLF (binmode=1 default)");
} else {
    is($out, "a\n", "Unix-like OS preserves LF");
}

# Test 2: Explicit binary(0) to get old behavior
eval "use IPC::Run qw(binary)";
SKIP: {
    skip "binary() filter not available", 1 if $@;
    my $out2;
    run([$^X, '-e', 'print "a\n"'], \undef, binary(0), \$out2);
    is($out2, "a\n", "Explicit binary(0) restores newline translation");
}

diag "Captured output (hex): " . unpack("H*", $out);

done_testing();
