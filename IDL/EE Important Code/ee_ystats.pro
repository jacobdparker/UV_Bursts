;PROGRAM: ee_ystats
;PURPOSE: compute height of image boxes and plot against different values
;PARAMETERS:
;  dat_array=array containing dimension data for event boxes
;  dates=array of Julian dates of each observation
;  count=array of number of boxes on each image
;VARIABLES:
;  depth=number of observations
;  heights=2D array of heights of each event in each observation in arcsec
;  avg_heights=array of average height of an event during each
;              observation in arcsec
;  dev_heights=array of standard deviations of heights of each event
;               during each observation
;  obs,i,n=counting variable
;  y0,y1=temporary arrays containing top and bottom position
;  char=plot selection character
;  p=plot
;PRODUCES: plots
;AUTHOR(S): A.E. Bartz, 6/12/17

pro ee_ystats, dat_array, dates, counts

;Initialize arrays
  depth=n_elements(counts)
  heights=fltarr(100,depth)
  avg_heights=fltarr(depth)
  dev_heights=fltarr(depth)

;Find saved fits header files
  fitsheads=file_search('../EE_Data','obsinfo*.sav')

;Compute arrays containing each event's width and the average height
  for obs=0,depth-1 do begin
     y0=dat_array[*,2,obs]
     y1=dat_array[*,3,obs]

;Crop data arrays to actual number of events to omit extra zeroes
     y0=y0[0:counts[obs]]
     y1=y1[0:counts[obs]]
     
     h=ee_boxheights(y0, y1, fitsheads[obs])
     heights[0,obs]=h
     avg_heights[obs]=mean(h)
     dev_heights[obs]=stdev(h)
  endfor
  
;Compute & print average length of time for all events
  print, "The average physical height of an event for all observations is "+$
         strcompress(mean(avg_heights), /remove_all)+$
         " units and the standard deviation is "+$
         strcompress(stddev(avg_heights), /remove_all)+" units"

;Let user decide which plots they want to generate
  i=0
  while i eq 0 do begin

     char=''
     print, "Which plot do you want to produce?"
     print, format='(%"a - average box physical height of each observation\nh - physical box height for all boxes\nq - quit and return to kernel")'
     read, char, prompt="Type your selection here: "

     case char of
        'a': begin
;Plot the average width of each observation with or without error bars
           p=plot(dates, avg_heights, title="Average height of event boxes", $
                  xtitle="Julian date", /sym_filled, linestyle=6, $
                  YTITLE="Average height of events (arcsec)", $
                  /WIDGETS, sym_transparency=50, symbol='o', $
                  rgb_table=43, xtickinterval=365)
        end

        'h': begin
           p=plot(make_array(counts[0],value=dates[0]),heights[0:counts[0],0], $
                  /WIDGETS, symbol='o', /sym_filled, linestyle=6, $
                  xtickinterval=365, xrange=[dates[0]-50,dates[-1]+50], $
                  rgb_table=43, xtitle="Julian date", $
                  ytitle="Actual height of events (arcsec)",$
                  title="Physical height on slit for all event boxes")
           for n=1,31 do begin
              p=plot(make_array(counts[n],value=dates[n]), $
                     heights[0:counts[n],n], symbol='o', /sym_filled, $
                     rgb_table=43, linestyle=6, sym_transparency=50, $
                     /OVERPLOT)
           endfor
        end

        'q': i=1

        else: print, "Invalid input."
     endcase
  endwhile
  
  print, "Returning to kernel."     
end

