#!/usr/bin/perl -T
# Matija Nalis <malis-git@voyager.hr> release under AGPLv3 or higher; started 2025-11-16

use strict;
use warnings;
use Text::CSV;
use Time::Piece;
use open ':std', ':encoding(UTF-8)';
use feature 'say';

my $DEBUG = $ENV{'DEBUG'} || 0;

# Expected header fields
my @header = (
    "url","username","password","httpRealm","formActionOrigin",
    "guid","timeCreated","timeLastUsed","timePasswordChanged"
);

my $expected_header = join(",", @header);

my %entries;        # key: guid -> entry hashref
my %seen_url_user;  # key: url|username -> guid

my $csv = Text::CSV->new({ binary => 1, auto_diag => 1, strict => 1, strict_eol => 1, blank_is_undef => 1 });

foreach my $file (@ARGV) {
    open my $fh, "<:encoding(utf8)", $file
        or die "Cannot open $file: $!";

    my $row = $csv->getline($fh);
    my $hdr = join(",", @$row);

    # Header mismatch check
    if ($hdr ne $expected_header) {
        say STDERR "ERROR: Header mismatch in file '$file'";
        exit 1;
    }

    # Process rows for current .csv file
    while (my $r = $csv->getline($fh)) {
        my %rec;
        @rec{@header} = @$r;

        my $guid = $rec{guid};
        my $key  = $rec{url} . "|" . $rec{username};

        # Warn if url+username already seen with different GUID
        if (exists $seen_url_user{$key} && $seen_url_user{$key} ne $guid) {
            $DEBUG > 0 && say STDERR "NOTICE: url+username ($rec{url}, $rec{username}) appear under different GUIDs ($seen_url_user{$key} vs $guid)";
        }
        $seen_url_user{$key} = $guid;

        # If that guid was already seen, compare entries
        if (exists $entries{$guid}) {
            my $old = $entries{$guid};

            # Warn if GUID is same but url+username differs
            if ($old->{url} ne $rec{url} || $old->{username} ne $rec{username}) {
                say STDERR "WARNING: GUID $guid has differing url+username across files.";
            }

            # Conflict detection
            my $old_last = $old->{timeLastUsed};
            my $old_pwd  = $old->{timePasswordChanged};
            my $new_last = $rec{timeLastUsed};
            my $new_pwd  = $rec{timePasswordChanged};

            if (($new_last > $old_last && $new_pwd < $old_pwd) ||
                ($new_last < $old_last && $new_pwd > $old_pwd)) {
                say STDERR "WARNING: GUID $guid conflict: one entry has newer timeLastUsed, other newer timePasswordChanged.";
            }

            # Choose best (newest password change; tie-break by last used)
            my $replace = 0;
            if ($rec{timePasswordChanged} > $old->{timePasswordChanged}) {
                $replace = 1;
            } elsif ($rec{timePasswordChanged} == $old->{timePasswordChanged}) {
                if ($rec{timeLastUsed} > $old->{timeLastUsed}) {
                    $replace = 1;
                }
            }

            $entries{$guid} = \%rec if $replace;
        }
        else {
            $entries{$guid} = \%rec;
        }
    }

    close $fh;
}

# Output merged CSV
my $csv_out = Text::CSV->new({ binary => 1, always_quote => 1, eol => "\r\n" });

# Print header
$csv_out->print(*STDOUT, \@header);

# Print rows
foreach my $guid (sort keys %entries) {
    my @vals = @{ $entries{$guid} }{@header};
    $DEBUG > 8 && say STDERR "DEBUG: printing GUID=$guid";
    $csv_out->print(*STDOUT, \@vals);
}

exit 0;
