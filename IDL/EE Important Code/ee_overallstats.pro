;PROCEDURE: ee_overallstats
;PURPOSE: Perform statistics on the entire IRIS data set
;PARAMETERS:
;  dat_array=an array containing all of the x0,x1,y0,y1 data from mouseread
;  dates=array containing the Julian dates of the observations
;  counts=array containing the number of boxes drawn per observation
;VARIABLES:
;  depth=number of observations
;  obs,n=counting variable
;  o14,o15,o16,o17=number of observations binned by year
;  b14,b15,b16,b17=number of boxes drawn binned by year
;  boxtots,obstots=arrays of binned values
;  labels=the bins' years
;  boxtotal,obstotal=sum of bin arrays
;  pcent_box,pcent_obs=arrays of percentage of boxes/observations in each bin
;SAVES:
;  Statistical plots (TBA)
;AUTHOR(S): A.E. Bartz 6/14/17

pro ee_overallstats, dat_array, dates, counts

  depth=n_elements(counts)
  b14=0
  o14=0
  b15=0
  o15=0
  b16=0
  o16=0
  b17=0
  o17=0

;Bin boxes by year and count number of observations per year
  for obs=0,depth-1 do begin
     if ((dates[obs] ge 2456658.5) AND (dates[obs] lt 2457023.5)) then begin
        b14=b14+counts[obs]
        o14++
     endif
     if ((dates[obs] ge 2457023.5) AND (dates[obs] lt 2457388.5)) then begin
        b15=b15+counts[obs]
        o15++
     endif
     if ((dates[obs] ge 2457388.5) AND (dates[obs] lt 2457754.5)) then begin
        b16=b16+counts[obs]
        o16++
     endif
     if dates[obs] ge 2457754.5 then begin
        b17=b17+counts[obs]
        o17++
     endif
  endfor

;Make arrays of binned values  
  boxtots=[b14,b15,b16,b17]
  obstots=[o14,o15,o16,o17]
  labels=[2014,2015,2016,2017]
  
;Bar plot binned boxes
  b1=barplot(labels,boxtots, /widgets, $
            title='Total number of boxes and observations per year', $
            fill_color='magenta', xtitle='Year', $
            ytitle='Box (teal) and observation (magenta) count')
  b2=barplot(labels,obstots,/widgets, fill_color='teal',/OVERPLOT, $
             bottom_values=boxtots)

;Percentage statistics by year
  boxtotal=total(boxtots)
  obstotal=total(obstots)
  pcent_box=boxtots/boxtotal*100
  pcent_obs=obstots/obstotal*100
  
  print, format='(%"\nPercentage of observations and boxes drawn by year")'
  for n=0,3 do print, string(labels[n])+": "+$
         strcompress(pcent_obs[n], /remove_all)+"% of all observations and "+$
         strcompress(pcent_box[n], /remove_all)+"% of all boxes drawn."
                                                              
end

        
