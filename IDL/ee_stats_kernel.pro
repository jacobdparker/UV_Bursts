;KERNEL
;PURPOSE: Perform variety of statistical functions on EE data  based
;on user input
;VARIABLES:
;  files=array of filepaths of ee.sav files
;  arr=array of x0,x1,y0,y1 data for each of ee.sav files
;  counts=array of number of boxes drawn in each ee.sav file
;  dates=array of julian dates of each ee.sav observation
;  i,j=counting variables
;  input,char=character input read from terminal
;FIND DESCRIPTIONS OF OUTSOURCED FUNCTIONS/PROCEDURES IN THEIR INDIVIDUAL FILES
;AUTHOR(S): A.E.Bartz 6/9/17

print, "This program performs statistical analyses on IRIS sit and stare data."

varfile=file_search('variables.sav')
if varfile ne '' then begin
   restore, varfile
   varfile=!NULL                ;free memory
   print, "Data restored."
endif else begin
   print, "Initializing data..."
   files=file_search("../EE_Data","ee_*20.sav")
   print, 'Finding event dates...'
   dates=ee_pathdates(files)
   print, 'Assigning data boxes...'
   arr=ee_box_data(files)
   print, 'Assigning event counts...'
   counts=ee_event_counts(files)
   save, arr, dates, counts, file="variables.sav"
   files=!NULL                  ;free memory
endelse

i=0

while i eq 0 do begin
   print, format='(%"\nType one of the letters below to perform its corresponding analysis.")'
   print, format='(%"t - time statistics\ny - position statistics\nc - overall statistics for observation set\ns - scatter plots\nh - histograms\nw - gimme a second\nq - quit the program")'
   input=''
   READ, input, PROMPT='Type an option here: '

   case input of
      't':  ee_timestats, arr, dates, counts

      'y':  ee_ystats, arr, dates, counts

      'c':  ee_overallstats, arr, dates, counts
      
      'q': begin
         print, "Exiting the program..."
         i=1
      end

      's':  ee_scatter, arr, dates, counts

      'w':  STOP, "Ok, giving you a second! Type .c to continue when you're ready."

      'h': ee_hist, arr, dates, counts
      
      else:  print, "Invalid input."
      
   endcase

endwhile

end
