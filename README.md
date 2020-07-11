# Dependencies
* python 3.7.4
* pandas
* openpyxl
# USAGE
`./main.py --help`
## Example
This should work on `stable`:
`./main.py  SAS\ KNOWS\ HIV\ BURUNDI\ 2011\ Output.xlsx --cksy Burundi,Knows,2011 save bu_knows_11.png`

## Generating 4 complete pngs
* Two commands:

`./main.py SAS\ KNOW\ STATUS\ Output.xlsx save all_years`
`./main.py SAS\ ALL\ HIV+\ Output.xlsx save all_years`

* One-liner:
`./main.py SAS\ KNOW\ STATUS\ Output.xlsx save all_years && ./main.py SAS\ ALL\ HIV+\ Output.xlsx save all_years && open *.png`

# TODOs
* fix bug on interactive subcommand
* get png dimensions from user, rather than system display settings. It turns out that it comes out wider when using a 4k display rather than a 15" MBP Retina screen.