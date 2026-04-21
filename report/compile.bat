latexmk -xelatex -outdir=out cw.tex
rd ./cw.pdf
move out\cw.pdf .\cw.pdf