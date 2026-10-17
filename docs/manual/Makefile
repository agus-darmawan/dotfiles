# Build the user manual: make  (needs a TeX Live with latexmk)
manual.pdf: manual.tex preamble.tex chapters/*.tex figures/*
	latexmk -pdf -interaction=nonstopmode -halt-on-error manual.tex

clean:
	latexmk -C manual.tex

.PHONY: clean
