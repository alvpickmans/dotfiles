" Below code loads each configuration file within this directory
for f in split(glob('$HOME/Appdata/Local/nvim/config/*.vim'), '\n')
	exe 'source' f
endfor
