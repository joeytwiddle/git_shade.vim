" git_shade.vim - Colors lines in different intensities according to their age in git's history
" Run :GitShade to shade the file.  Switch buffer or :e the file to remove the shading.
" git_shade assumes you have a black background.  If not, you are likely to have a bad time.

" TODO: Should seek .git folder from the buffer file's path, in case our pwd is not within the project.

" === Options ===

if !exists("g:GitShade_ColorGradient") || !exists("g:GitShade_ColorWhat")
  let g:GitShade_ColorGradient = "black_to_blue"
  let g:GitShade_ColorWhat = "bg"
  "let g:GitShade_ColorGradient = "green_to_white"
  "let g:GitShade_ColorWhat = "fg"
endif

" Linear mode (1) is good for comparing the ages of all the lines in the file.
" Non-linear mode (0) is better at indicating the most recent lines; most older lines fade to black.
if !exists("g:GitShade_Linear")
  let g:GitShade_Linear = 0
endif

" === Commands ===

command! GitShade call s:GitShade(expand("%"))
"command! GitHighlightRecentLines call s:GitShade(expand("%"))
"command! GitGlowRecentLines call s:GitShade(expand("%"))

" === Script ===

function! s:GitShade(filename)

  if !has("gui_running")
    echo "Only works in GUI mode."
    return
  endif

  let cmd = "git blame --line-porcelain -t " . shellescape(a:filename)

  echo "Doing: " . cmd

  let data = system(cmd)

  let lines = split(data,'\n')

  let timesDictionary = {}
  let b:gitBlameLineData = ["there_is_no_line_zero"]
  let earliestTime = localtime()
  let latestTime = 0

  let timeNum = -1
  let author = ""
  let summary = ""
  let nextLineIsContent = 0
  let lineNum = 0
  for line in lines

    if nextLineIsContent
      let lineNum += 1
      "call add(times, timeNum)
      if !exists("timesDictionary[timeNum]")
        let timesDictionary[timeNum] = []
      endif
      let list = timesDictionary[timeNum]
      call add(list, lineNum)
      let nextLineIsContent = 0
      if timeNum > latestTime
        let latestTime = timeNum
      endif
      if timeNum < earliestTime
        let earliestTime = timeNum
      endif
      let dateStr = strftime("%d/%m/%y %H:%M", timeNum)
      call add( b:gitBlameLineData, dateStr." (".author.") ".summary )
    else

      let words = split(line,' ')

      if words[0] == "committer-time"
        let timeNum = str2nr(words[1])
      elseif words[0] == "author"
        let author = join(words[1:],' ')
      elseif words[0] == "summary"
        let summary = join(words[1:],' ')
      elseif words[0] == "filename"
        let nextLineIsContent = 1
      endif

    endif

  endfor

  if line("$") != lineNum
    echo "WARNING: buffer linecount " . line("$") . " does not match git blame linecount " . lineNum
  endif

  " TODO: These options should be made configurable

  " In active projects, intensity can represent age relative to now
  let mostRecentTime = localtime()
  " But in old projects or old files, we may want to show changes relative to the last commit, even if it was made years ago
  "let mostRecentTime = latestTime

  " Lines older than 2 weeks are colored normally
  "let maxAge = 14 * 24 * 60 * 60
  " Only lines from the very first commit are colored normally
  let maxAge = mostRecentTime - earliestTime
  " Only shade lines in the second half of the file's history
  "let maxAge = (mostRecentTime - earliestTime) / 2.0
  " How fast should intensity fade as we move into the past?
  " Just enough to give a faint shade to the first commit:
  let halfLife = (mostRecentTime - earliestTime) / 16.0
  " Or constant: intensity halves every two weeks
  "let halfLife = 60*60*24*14

  " We need these to be floats for later calculations
  let maxAge = maxAge * 1.0
  let halfLife = halfLife * 1.0

  silent! call clearmatches()

  "let lineNum = 0
  "for timeNum in times
  for [timeNum, linesThisCommit] in items(timesDictionary)

    "let lineNum += 1

    let timeSince = mostRecentTime - timeNum
    if timeSince < 0
      let timeSince = 0
    endif
    if timeSince > maxAge
      let timeSince = maxAge
      " Skip doing any highlighting on old/unshaded lines
      " Only applies to some themes.
      if g:GitShade_ColorWhat == "bg" && match(g:GitShade_ColorGradient, "^black")==0
        continue
      endif
    endif

    if g:GitShade_Linear
      " Linear: intensity interpolates from min to max over time range
      let intensity = 255.0 * ( 1.0 - timeSince / maxAge )
    else
      " Exponential: intensity halves every halfLife
      let intensity = 255.0 / (1.0 + timeSince / halfLife)
    endif
    let intensity = float2nr(intensity)
    let iHex = printf('%02x', intensity)

    " NOTE: In future we may want to interpolate between two provided colors.  If they are provided in hex, we can use str2nr(hexStr, 16) to obtain a decimal.
    if g:GitShade_ColorGradient == "black_to_green"
      let hlStr = "00" . iHex . "00"
    elseif g:GitShade_ColorGradient == "green_to_white"
      let hlStr = iHex . "ff" . iHex
    elseif g:GitShade_ColorGradient == "black_to_blue"
      let hlStr = "0000" . iHex
    elseif g:GitShade_ColorGradient == "black_to_grey"
      let iHex = printf('%02x', intensity/2)
      let hlStr = iHex . iHex . iHex
    elseif g:GitShade_ColorGradient == "grey_to_black"
      let iHex = printf('%02x', 128-intensity/2)
      let hlStr = iHex . iHex . iHex
    endif

    "echo "Hex for age " . timeNum . " is: " . hlStr

    let hlName = "GitShade_" . hlStr

    if hlexists(hlName)
      exec "highlight clear " . hlName
    endif

    "echo "timeSince=" . timeSince . " maxAge=" . maxAge . " intensity=" . intensity

    if g:GitShade_ColorWhat == "fg"
      exec "highlight " . hlName . " guifg=#" . hlStr . " gui=none"
    else
      exec "highlight " . hlName . " guibg=#" . hlStr
    endif

    "let pattern = "\\%" . lineNum . "l"
    let pattern = join( map(linesThisCommit,'"\\%" . v:val . "l"'), '\|' )

    call matchadd(hlName, pattern)

    "if lineNum > 20
    "  break
    "endif

  endfor

  exec "highlight Normal guibg=black"

  augroup GitShade
    autocmd!
    autocmd BufWinEnter * call clearmatches()
    autocmd CursorHold <buffer> call s:ShowGitBlameData()
    " Note that because we define it only on this buffer, running :GitShade will remove ShowGitBlameData from other buffers.
  augroup END

  " Creating all these pattern matches makes rendering very inefficient.
  " The time taken to render will probably grow linearly with the number of lines in the file (the number of matches we create).
  " DONE: To reduce this, we could group together times which are the same, and create just one pattern for each unique timestamp, which would highlight multiple lines.
  " As done here: http://stackoverflow.com/questions/13675019/vim-highlight-lines-using-line-number-on-external-file?rq=1
  " CONSIDER: Alternatively, we could use the 'signs' column to indicate different ages, and highlight lines through that.

endfunction

function! s:ShowGitBlameData()
  if exists("b:gitBlameLineData")
    let data = get(b:gitBlameLineData, line("."), "no_git_blame_data")
    " Truncate string if it will not fit in command-line
    if strdisplaywidth(data) > &ch * &columns
      let data = strpart(data, 0, &ch * &columns)
    endif
    echo data
  endif
endfunction

