#!/usr/bin/env perl

use Getopt::Long;
use Pod::Usage;
use File::Find;
use File::Spec::Functions;
use v5.38;

# converts a hash to todo file content
# ------------------------------------
sub hash_to_todo(%hash) {
    my $result;
    # first dump the parentless todo
    for my $todo_hash ($hash{todo}->@*) {
        my ($todo, $status) = $todo_hash->@{'todo', 'status'}; 
        $result .= sprintf "- [%s] %s\n", ($status == 1 ? 'X' : ' '), $todo;
    }
    # then dump the todos with filepath as parent
    delete $hash{todo};
    for my $file_path (keys %hash) {
        $result .= "$file_path:\n";
        for my $todo_hash ($hash{$file_path}->@*) {
            my ($todo, $status) = $todo_hash->@{'todo', 'status'}; 
            $result .= sprintf "    - [%s] %s\n", ($status == 1 ? 'X' : ' '), $todo;
        }
    }
    return $result;
}

# converts a todo file content to hash
# ------------------------------------
sub todo_to_hash($todo) {
    my %result;
    my $current_file;
    my @lines = split '\n', $todo;
    for (@lines) {
        # if its a filepath
        if (not /^- / and /^(.+):$/) {
            $current_file = $1;
            $result{$current_file} = ();
        # if its a parentless todo (without indentation)
        } elsif (/^- \[(?<done>[Xx ])\] (?<todo>.+)/) {
            push @{$result{todo}}, { todo => $+{todo}, status => $+{done} eq ' ' ? 0 : 1};
        # if its a todo with a parent filepath (has indentation)
        } elsif (/^\s+- \[(?<done>[Xx ])\] (?<todo>.+)/) {
            push @{$result{$current_file}}, { todo => $+{todo}, status => $+{done} eq ' ' ? 0 : 1 };
        }
    }
    return %result;
}

# quick and dirty replacements for Path::Tiny
# -------------------------------------------
sub slurp($filepath) {
    open my $file, '<', $filepath or die "open(): $!";
    wantarray ? map {chomp; $_} (<$file>) : join '', <$file>;
}
sub spit($filepath, $data) {
    open my $file, '>', $filepath or die "open(): $!";
    print $file $data;
}

# parsing arguments
# -----------------
pod2usage(0) if @ARGV == 0;
Getopt::Long::Configure ("bundling");
GetOptions(
    "l|list" => \my $list,
    "u|undone" => \my $undone,
    "v|verbose" => \my $verbose,
    "h|help" => sub { pod2usage(0) },
) or pod2usage(1);
pod2usage({-message => "error: missing DIRECTORY", -exitval => 1}) if @ARGV == 0;
my $directory_path = $ARGV[0] =~ s/^\.\///r; # remove the optional ./ from the directory path

# check if directory exists
# -------------------------
die "$directory_path: No such readable directory\n" unless -d $directory_path and -e $directory_path; 

# load TODO.md and .todoignore if exists
# --------------------------------------
my $todo_path = catfile($directory_path, "TODO.md");
my $todoignore_path = catfile($directory_path, ".todoignore");
my %old_todo = (-e $todo_path and -r $todo_path) ? todo_to_hash(scalar slurp($todo_path)) : ();
my $todoignore = (-e $todoignore_path and -r $todoignore_path) ? join '|', slurp($todoignore_path) : undef;
my %todo;

# loop through files to add the TODOs
# -----------------------------------
find(sub {
    return unless -f and -r and (-s) < (10 * 1024 * 1024); # skip 10M+ files
    my $filepath = $File::Find::name;
    say "checking $filepath" if $verbose;
    if ($todoignore and $filepath =~ /$todoignore/) {
        say "skipped because matches todoignore pattern" if $verbose;
        return;
    }
    my @todos = map { /TODO[: ]+(.+)$/; {todo => $1, status => 0} } grep { /^(#|--|\/\/|;)(\s+)?TODO[: ]+(.+)$/ } (slurp($_));
    $todo{$filepath} = [] if @todos;
    for my $todo (@todos) {
        push @{$todo{$filepath}}, $todo;
    }
}, $directory_path);

# diff between maybe existing TODO.md and in memory TODOs
# -------------------------------------------------------
push $todo{todo}->@*, $old_todo{todo}->@* if $old_todo{todo};
delete $old_todo{todo};
for my $filepath (keys %old_todo) {
    for my $old_todo ($old_todo{$filepath}->@*) {
        unless (grep { $old_todo->{todo} eq $_->{todo} } $todo{$filepath}->@*) {
            push $todo{$filepath}->@*, {todo => $old_todo->{todo}, status => 1};
        }
    }
}

# dump the todo to TODO.md and show undone task to STDOUT
# -------------------------------------------------------
my $todo_md = hash_to_todo(%todo);
if ($list) {
    print $todo_md if $list;
} else {
    spit($todo_path, $todo_md);
    my @undone = grep { $_->{status} == 0 } $todo{todo}->@*;
    print map { "- [ ] $_->{todo}\n" } @undone;
    delete $todo{todo};
    for my $filepath (keys %todo) {
        my @undone = grep { $_->{status} == 0 } $todo{$filepath}->@*;
        say "$filepath:" if @undone;
        print map { "    - [ ] $_->{todo}\n" } @undone;
    }
}

__END__

=head1 NAME

todo - a simple todo manager

=head1 SYNOPSIS

    todo [OPTIONS] DIRECTORY

    Options:
        -h, --help       show this help message
        -l, --list       show the TODOs without updating TODO.md
        -v, --verbose    show each path before processing them

=head1 DESCRIPTION

I<todo> is a simple perl script that help managing your TODO in a project.

It takes a directory to analyze as argument and will generate a TODO.md at the root of that directory with the found TODO.

If a I<TODO.md> is already in the root of the directory, I<todo> will update that file, eventually marking some TODO as completed if they are not found in any sub path.

=head1 PARENTLESS TODOs

TODOs with no filepath as parent will not be tracked, they require to be automatically added and marked as
done in TODO.md.

=head1 PROCESS

=over

=item *

Check if there is a I<TODO.md> in the target directory. If yes, load it as a hash.

=item *

Loop recursively in the filesystem to find all file that are readable and less than 10Mb in size.

When finding one, will loop through the lines of the file and capture all TODOs which can be in those formats:

    TODO something to do
    TODO  something to do
    TODO: something to do
    TODO:  something todo
    ...

Basically any amount of I<:> or space can be added after the word I<TODO>.

=item *

Will loop through the TODOs in the I<TODO.md> if any, to see which TODOs to mark as done (if they are not found in the files we check earlier).

But skip the parentless TODOs are those one cannot be tracked (no file to check).

=item *

Finally, the todo hash will be converted into a markdown TODO list and depending on the given options will update the I<TODO.md> or print it to STDOUT.

By default I<todo> will update I<TODO.md> and only show pending tasks to STDOUT.

=back

=head1 IGNORE

If you add a I<.todoignore> file at the root of the directory to analyse, I<todo> will skip matching path(s).

=head1 AUTHOR

4zv4l I<4zv4l@protonmail.com>
