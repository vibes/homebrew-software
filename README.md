homebrew-software
=================

Homebrew Tap for vibes specific software

How do I install these formulae?
--------------------------------
Just `brew tap vibes/software` and then `brew install <formula>`.

If the formula conflicts with one from mxcl/master or another tap, you can `brew install vibes/software/<formula>`.

You can also install via URL:

```
brew install https://raw.github.com/vibes/homebrew-software/master/<formula>.rb
```

How do I update a package without reinstalling?
----------------------------------------------
for many of the formula, you can re-run the post install steps for
helpful updates.

```
brew postinstall <formula>
```

Test Edit
---------

This is a test edit

Docs
----
`brew help`, `man brew`, or the Homebrew [wiki][].

[wiki]:http://wiki.github.com/mxcl/homebrew
