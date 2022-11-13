#!/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use Tie::File;
use feature 'say';

# Check Arguments
$ARGV[0] || usage(0);
GetOptions (
    "h" => \ my $help,
    "p" => \ my $pending,
) or usage(1);
if($help) {usage(0)}
# Check if dir is given and exists
$ARGV[0] || usage(2);
my $dir = $ARGV[0];
-d $dir || usage(3);

# open the TODO.tmp file and load config
my $todo_tmp = "$dir/TODO.tmp";
my $todo_md = "$dir/TODO.md";
tie my @file_tmp, 'Tie::File', "$todo_tmp"
    or die "tmp file opening: $!\n";
my @skip_files = load_config();

# loop through the dir recursively
find(
    {
        wanted => sub { process_file($_) unless -d },
        no_chdir => 1
    },
    $dir
);

# if TODO.md exist check for tasks done/undone
if (-f $todo_md && -r $todo_md) {
    tie my @file_md, 'Tie::File', "$todo_md"
        or die "couldn't open $todo_md: $!\n";
    for(@file_md) {
        # mark todo undone if found
        # otherwise append them to the TODO.tmp
        # (keep track of TODO marked as done)
        if($_ =~ /- \[X\] (.*?): (.*)$/) {
            my ($file, $todo) = ($1, $2);
            if(fgrep("$todo", @file_tmp)){    
                push @file_tmp, "- [ ] $file: $todo";
            } else {
                push @file_tmp, "- [X] $file: $todo";
            }
        }
        # mark todo done if not found anymore
        if($_ =~ /- \[ \] (.*?): (.*)$/) {
            my ($file, $todo) = ($1, $2);
            if(!fgrep("$todo", @file_tmp)){    
                push @file_tmp, "- [X] $file: $todo";
            }
        }
    }
}

# move .tmp to .md
rename($todo_tmp, $todo_md);

# if -p show undone task
if($pending) { show_undone() }

# add TODOs from a file to the TODO.md
sub process_file {
    my ($filename) = @_;
    if ( grep( /^$filename$/, @skip_files ) ) {
        return;
    }
    tie my @tmp, 'Tie::File', $filename
        or do {warn "couldn't process $filename: $!\n", return};
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

# return 1 if substring in file
sub fgrep {
    my ($str, @file) = @_;
    my $found = 0;
    for(@file) {
        if ($_ =~ /$str/) { $found = 1; last }
    }
    return $found;
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

sub usage {
    my $exit_code = $_[0];
    if($exit_code == 2) { warn "no directory to analyze\n\n" }
    if($exit_code == 3) { warn "$dir: not a directory\n\n" }
    print
"todo [OPTIONS] [Directory]

OPTIONS:
   -h              show this help
   -p              show undone tasks
Directory:
   The Directory to analyse
Ignore:
   Can write a [Directory]/.todoignore
   That will contain files to ignore
   Their path should start from [Directory]/
   Example: project/lib/std.h\n";
    exit $exit_code;
}
