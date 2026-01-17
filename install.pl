#!/usr/bin/perl

use strict;
use File::Spec;
use FindBin qw($Bin);
use File::Copy qw(copy);

my $src = File::Spec->catfile($Bin, 'vimrc');

-f $src or die "vimrc not found";

my $home = $ENV{HOME} || $ENV{USERPROFILE} || die "\$HOME not set";
my $vimrc = $^O eq 'MSWin32' ? '_vimrc' : '.vimrc';
my $dst = File::Spec->catfile ($home, $vimrc);

copy($src, $dst)
  or die "failed to copy $src to $dst: $!";

print "Installed vimrc to $dst\n";
