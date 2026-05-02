#!/usr/bin/perl -w

use strict;
use Test::More;
use Config;

diag "--- Diagnostics ---";
diag "Perl version: $]";
diag "Perl executable: $^X";
diag "OS: $^O";

for my $mod (qw(IPC::Run Sort::Naturally CPAN::Version Test::More Test::Differences)) {
    if (eval "require $mod; 1") {
        my $ver = eval "\$${mod}::VERSION";
        diag "$mod version: " . (defined $ver ? $ver : "unknown");
    } else {
        diag "$mod is NOT installed";
    }
}

diag "--- Environment ---";
for my $env (sort keys %ENV) {
    if ($env =~ /^(PERL|PATH|APPVEYOR|GITHUB|CI)/) {
        diag "$env=$ENV{$env}";
    }
}

if ($ENV{GITHUB_ACTIONS} || $ENV{APPVEYOR}) {
    diag "--- Git Config ---";
    my $git_crlf = `git config core.autocrlf`;
    if ($? == 0) {
        chomp $git_crlf;
        diag "git core.autocrlf: " . ($git_crlf || "not set");
    } else {
        diag "git config core.autocrlf failed or git not available";
    }
}

diag "--- Line Endings ---";
for my $file (qw(Makefile.PL bin/psort t/psort.t)) {
    if (-f $file) {
        open my $fh, '<', $file or next;
        binmode $fh;
        my $content;
        read $fh, $content, 1024;
        close $fh;
        if ($content =~ /\r\n/) {
            diag "$file: CRLF";
        } elsif ($content =~ /\n/) {
            diag "$file: LF";
        } elsif ($content =~ /\r/) {
            diag "$file: CR";
        } else {
            diag "$file: unknown or empty";
        }
    } else {
        diag "$file: NOT FOUND";
    }
}

diag "--- Compilation Check ---";
my $psort = "bin/psort";
if (-f $psort) {
    my $output = `$^X -c $psort 2>&1`;
    diag "Compilation of $psort: $output";
    ok($? == 0, "Compilation check of $psort");
} else {
    fail("$psort NOT FOUND");
}

ok(1, "Diagnostics completed");

done_testing();
