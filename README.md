# `yank-delimiters`

A variation of `yank` that is aware of delimiters,
and deletes extraneous ones before putting the string into the buffer.
See [this blog post](https://tony-zorman.com/posts/yanking.html)
for a more extensive overview.

## Installation

If you are on a recent enough version of Emacs 30,
you can install this package with `use-package` directly:

``` emacs-lisp
(use-package yank-delimiters
  :vc (:url "https://github.com/slotThe/yank-delimiters")
  :bind ("C-y" . yank-delimiters-yank))
```

Alternatively,
[vc-use-package](https://github.com/slotThe/vc-use-package)
provides a shim for Emacs 29 users.

``` emacs-lisp
(use-package yank-delimiters
  :vc (:fetcher github :repo "slotThe/yank-delimiters")
  :bind ("C-y" . yank-delimiters-yank))
```

Installing manually is possible as well, of course;
for that just copy the file to a convenient location and require it:

``` emacs-lisp
(require 'yank-delimiters)
(bind-key "C-y" #'yank-delimiters-yank)
```
