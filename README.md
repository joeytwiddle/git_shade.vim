git_shade.vim
=============

Colors lines in different intensities according to their age in git's history

Run `:GitShade` to shade the file, and again to turn it off.

This works best in Vim's gui mode, but there is now support for 8, 16 and 256 terminal colour mode too.

Some possible options (see the plugin file for more):

    let g:GitShade_ColorGradient = "black_to_blue"
    let g:GitShade_ColorWhat = "bg"

    let g:GitShade_ColorGradient = "green_to_white"
    let g:GitShade_ColorWhat = "fg"

    " Use grays instead of blues in 256-color terminal:
    let g:GitShade_Colors_For_CTerm_256 = [ 0, 232, 233, 234, 235, 236, 237, 238, 239 ]

In the screenshots below, the brighter blue background indicates a more recent addition.

With `let g:GitShade_Linear = 0` (default) the recent additions stand out clearly:

<img width="800" src="https://joeytwiddle.github.io/git_shade.vim/images/readme/git-shade-linear-0.png">

With `let g:GitShade_Linear = 1` we can see the relative ages of all lines in the file:

<img width="800" src="https://joeytwiddle.github.io/git_shade.vim/images/readme/git-shade-linear-1.png">

Changelog:

- May 2014: Support (with limited colors) for 8, 16 and 256-color terminals.  (Vim's `t_Co` option should be set appropriately.)
- June 2013: Committer name, date and message for current line is now displayed in command line area.

Related:

- [smeargle](https://github.com/FriedSock/smeargle) is a similar script which also offers a mode to highlight different committers.
- [fugitive.vim](https://github.com/tpope/vim-fugitive) provides a host of useful git tools, including `:Gblame` which presents info in the sidebar.
- [Gitv!](https://github.com/gregsexton/gitv) lets you select a range of lines and then walk through all their previous commits.
