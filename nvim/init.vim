" Below code loads each configuration file within this directory
let configPath = stdpath('config')
let vimPattern = configPath..'/config/*.vim'
echo configPath
echo vimPattern

for f in split(glob(vimPattern), '\n')
	exe 'source' f
endfor

