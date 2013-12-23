shotvibe-ios-client
===================

ShotVibe Client App for iPhone and iPad

## Coding Rules

### Adding New Files to the project

-   Make sure that new files are placed in the file system in the same
    directory that matches the group in which you placed the file in the Xcode
    Project Navigator.

-   Make sure that new files are sorted correctly inside their group in the
    Xcode Project Navigator. This can easily be achieved after adding new files
    to the project by selecting all of the files in the group, and running
    `"Edit" -> "Sort" -> "By Name"`

### Coding Style

-   All new code must conform to the uncrustify style as dictated by the
    included "uncrustify.cfg". When you do a build in Xcode, warnings will show
    up in the file you are working on that show the locations of style
    violations. Make sure to fix these before committing.

-   Do not fix the style in parts of the code that you are not working on! This
    will make your commits messy, and will mess up history. There is lots of
    legacy code with style violations (which will be fixed eventually in one
    shot). Just make sure that all new code that you write doesn't introduce
    any new style warnings.

-   Note: uncrustify, and the given config, are not perfect. Make suggestions
    for tweaking uncrustify.cfg. In cases where you are sure that uncrustify is
    reporting inferior formatting (and you are unable to tweak the config to be
    correct): surround the relevant code with comments containing
    `*INDENT-OFF*` and `*INDENT-ON*`. Hopefully future versions of uncrustify
    will handle it properly (report a bug to uncrustify!)
