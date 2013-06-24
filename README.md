git_shade.vim
=============

Colors lines in different intensities according to their age in git's history

Run `:GitShade` to shade the file.  Switch buffer or `:e` the file to remove the shading.

Naturally this only works in Vim's GUI mode.

Some possible options (see the plugin file for more):

    let g:GitShade_ColorGradient = "black_to_blue"
    let g:GitShade_ColorWhat = "bg"

    let g:GitShade_ColorGradient = "green_to_white"
    let g:GitShade_ColorWhat = "fg"

For example, the bright blue background indicates the most recent addition to this source file:

![Showing some the latest additions to a C++ file](http://neuralyte.org/~joey/git_shade/git_shade/screenshot-25665.png)

