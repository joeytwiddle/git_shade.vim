git_shade.vim
=============

Colors lines in different intensities according to their age in git's history

Run `:GitShade` to shade the file.  Switch buffer or `:e` the file to remove the shading.

Naturally this only works in Vim's GUI mode.

Caveat: This plugin is pretty raw, will set your background to black, and does not offer much in the way of cleanup.  Please fork and show it some love!

Some possible options (see the plugin file for more):

    let g:GitShade_ColorGradient = "black_to_blue"
    let g:GitShade_ColorWhat = "bg"

    let g:GitShade_ColorGradient = "green_to_white"
    let g:GitShade_ColorWhat = "fg"

In the screenshots below, the brighter blue background indicates a more recent addition.

With `let g:GitShade_Linear = 0` the recent additions stand out clearly:

![Showing the latest additions to a C++ file](http://neuralyte.org/~joey/git_shade/git_shade/git_shade_non_linear.png)

With `let g:GitShade_Linear = 1` we can see the relative ages of all lines in the file:

![Shading to show relative ages of all lines](http://neuralyte.org/~joey/git_shade/git_shade/git_shade_linear.png)

