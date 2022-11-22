#!/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use Tie::File;
use List::Util qw(any);
use feature 'say';

# Check Arguments
$ARGV[0] || usage(0);
GetOptions (
    "h" => \ my $help,
    "p" => \ my $pending,
    "x" => \ my $ignore,
) or usage(1);
if($help) {usage(0)}
# Check if dir is given and exists
my $dir = $ARGV[0] || usage(2);
-d $dir || usage(3);

# open the TODO.tmp file and load config
my $todo_tmp = "$dir/TODO.tmp";
my $todo_md = "$dir/TODO.md";
my $todo_bk = "$dir/.TODO.md.bak";
tie my @file_tmp, 'Tie::File', "$todo_tmp"
    or die "tmp file opening: $!\n";
my @skip_files = load_config();

# loop through the dir recursively
# adding todos to TODO.tmp
find(
    {
        wanted => sub { process_file($_) unless -d },
        no_chdir => 1
    },
    $dir
);

# if TODO.md exist and is readable check for tasks done/undone
if (-f $todo_md && -r $todo_md) {
    tie my @file_md, 'Tie::File', "$todo_md"
        or die "couldn't open $todo_md: $!\n";
    for(@file_md) {
        # if -x then ignores todos from .todoignore
        # from the previous TODO.md
        if($ignore) {
            if($_ =~ /- \[.\] (.*?): (.*)$/) {
                my ($file, $todo) = ($1, $2);
                next if any { $file =~ /$_/ } @skip_files;
            }
        }
        # mark todo undone if found
        # otherwise append them to the TODO.tmp
        # (keep track of TODO marked as done)
        if($_ =~ /- \[X\] (.*?): (.*)$/) {
            my ($file, $todo) = ($1, $2);
            unless(any {/$todo/} @file_tmp){    
                push @file_tmp, "- [X] $file: $todo";
            }
        # mark todo done if not found anymore
        } elsif($_ =~ /- \[ \] (.*?): (.*)$/) {
            my ($file, $todo) = ($1, $2);
            unless(any {/$todo/} @file_tmp){    
                push @file_tmp, "- [X] $file: $todo";
            }
        }
    }
    # move .md to .md.bak
    # backup the previous one in case
    # something went wrong
    rename($todo_md, $todo_bk);
}

# move .tmp to .md
rename($todo_tmp, $todo_md);

# if -p show undone task
if($pending) { show_undone() }

# add TODOs from a file to the TODO.md
sub process_file {
    my ($filename) = @_;
    return if any { $filename =~ /$_/ } @skip_files;
    tie my @tmp, 'Tie::File', $filename
        or do {warn "couldn't process $filename: $!\n"; return};
    for(@tmp) {
        if($_ =~ /TODO?[^ ]*(?:[\s]*)(.*?)\s*$/) {
            my $todo = $1;
            push @file_tmp, "- [ ] $filename: $todo";
        }
    }
}

# print undone task from TODO.md
sub show_undone {
    my $counter = 0;
    for(@file_tmp) {
        if($_ =~ /- \[ \] (?:.*?): (.*)$/) {
            say "- $1";
            $counter++;
        }
    }
    if($counter == 0) {
        say "No Task pending, you can rest now :)";
    }
}

# load $dir/.todoignore
# containing files to ignore
sub load_config {
    open my $config, "$dir/.todoignore"
        or return ();
    my @files;
    while(<$config>) {
        chomp;
        unless ($_ =~ /^$/ || $_ =~ /^\s/ || $_ =~ /\s$/) {
            push @files, $_;
        }
    }
    return @files;
}

# show how to use the script
# and a warning depending 
# on the exit code
sub usage {
    my $exit_code = $_[0];
    if($exit_code == 2) { warn "no directory to analyse\n\n" }
    if($exit_code == 3) { warn "$dir: not a directory\n\n" }
    print
"ptodo [OPTIONS] [Directory]

OPTIONS:
   -h              show this help
   -p              show undone tasks after analyse
   -x              do not append previous matching .todoignore
Directory:
   The Directory to analyse
Ignore:
   Can write a [Directory]/.todoignore
   Which contains files/extensions
   to skip when generating the TODO.md
Backup:
   In case something went wrong a backup of
   your previous `TODO.md` will be made as `.TODO.md.bak`\n";
    exit $exit_code;
}
