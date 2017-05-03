
ODG_CROPPED_PDF=$(shell ls -1 *.odg | sed -e 's/\..*$$/_cropped.pdf/')

%.pdf: %.odg
	soffice --convert-to pdf $< --headless

%_cropped.pdf: %.pdf
	pdfcrop $< $@

all: $(ODG_CROPPED_PDF)


default: all

clean:
	rm $(ODG_CROPPED_PDF)

