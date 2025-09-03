# `xpb` (Extended Pasteboard)

Extended access for the Mac OS pasteboards (clipboards) for command-line utilities.

Pull requests gladly accepted! Swift is not my first language.

## Installing

For the moment, this is self-serve: clone the repo and run `swift build -c release`.

Watch this space, though; I might have some releases built at some point.


## Usage

Example uses follow:

### `xpb copy`: writing to a pasteboard

Write plain text to the 'general' pasteboard from stdin:
```
% echo 'hello, world!' | xpb copy
```

Write RTF text to the 'general' pasteboard from stdin:
```
% echo '*hello, world!*' | pandoc --from=markdown --to=rtf | xpb copy --stdin-format rtf
```

Write multiple representations of the same data to the pasteboard (as when you copy rich text from
a web browser):

```
% echo '*hello, world!*' > example.markdown
% pandoc example.markdown --to=plain -o example.txt
% pandoc example.markdown --to=html -o example.html
% xpb copy html:example.html string:example.txt
```

... or the same thing, but using process substitution:

```
% echo '*hello, world!*' > example.markdown
% xpb copy html:<(pandoc --to=html example.markdown) string:<(pandoc --to=plain example.markdown)
```


### `xpb list`: listing pasteboard contents

List the contents of the general pasteboard after copying plaintext:
```
% xpb list
Pasteboard 'Apple CFPasteboard general' has 4 bytes of 'string' data.
```

... or after copying HTML text from Firefox:
```
% xpb list
Pasteboard 'Apple CFPasteboard general' has 404 bytes of 'html' data
Pasteboard 'Apple CFPasteboard general' has 98 bytes of 'string' data
```

... after right-click and 'copy image':
```
% xpb list
Pasteboard 'Apple CFPasteboard general' has 269 bytes of 'html' data
Pasteboard 'Apple CFPasteboard general' has 2601 bytes of 'png' data
Pasteboard 'Apple CFPasteboard general' has 11430 bytes of 'tiff' data
```

List the contents of the 'find' pasteboard:
```
% xpb list --name find
Pasteboard 'Apple CFPasteboard find' has 6 bytes of 'string' data
```

### `xpb paste`: printing pasteboard contents

Dump the contents of the general pasteboard:
```
% xpb paste
```

Dump the HTML contents of a pasteboard:
```
% xpb paste --format html
<b>hello, world!</b>
```

You can even dump binary data (e.g., `xpb paste --format png`) if you want to. Probably you should
pipe it to `base64`, though, to not screw up your terminal.

