# NAME

todo - a simple todo manager

# SYNOPSIS

    todo [OPTIONS] DIRECTORY

    Options:
        -h, --help       show this help message
        -l, --list       show the TODOs without updating TODO.md
        -v, --verbose    show each path before processing them

# DESCRIPTION

_todo_ is a simple perl script that help managing your TODO in a project.

It takes a directory to analyze as argument and will generate a TODO.md at the root of that directory with the found TODO.

If a _TODO.md_ is already in the root of the directory, _todo_ will update that file, eventually marking some TODO as completed if they are not found in any sub path.

# PARENTLESS TODOs

TODOs with no filepath as parent will not be tracked, they require to be automatically added and marked as
done in TODO.md.

# PROCESS

- Check if there is a _TODO.md_ in the target directory. If yes, load it as a hash.
- Loop recursively in the filesystem to find all file that are readable and less than 10Mb in size.

    When finding one, will loop through the lines of the file and capture all TODOs which can be in those formats:

        TODO something to do
        TODO  something to do
        TODO: something to do
        TODO:  something todo
        ...

    Basically any amount of _:_ or space can be added after the word _TODO_.

- Will loop through the TODOs in the _TODO.md_ if any, to see which TODOs to mark as done (if they are not found in the files we check earlier).

    But skip the parentless TODOs are those one cannot be tracked (no file to check).

- Finally, the todo hash will be converted into a markdown TODO list and depending on the given options will update the _TODO.md_ or print it to STDOUT.

    By default _todo_ will update _TODO.md_ and only show pending tasks to STDOUT.

# IGNORE

If you add a _.todoignore_ file at the root of the directory to analyse, _todo_ will skip matching path(s).

# AUTHOR

4zv4l _4zv4l@protonmail.com_
