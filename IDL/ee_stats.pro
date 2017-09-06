;FUNCTION: ee_pathdates
;PURPOSE: Compute dates of observations from the EE filepath array
;VARIABLES:
;  n=number of observation dates
;  dates=array of Julian dates for each observation
;  current=string in format "yearmonthday_hourminsec" with 15 characters
;  year, month, day, hour, minute, second = integers
;RETURNS: array of Julian dates
;AUTHOR(S): A.E. Bartz 6/9/17
function ee_pathdates

  ;Get the paths that lead to dates
  restore, "ee_obs_paths.sav"
  n=n_elements(ee_obs_path)
  dates=fltarr(n)

  ;Write the dates into array
  for i=0,n-1 do begin
     current=strmid(ee_obs_path[i],42,15)
     year=fix(strmid(current,0,4))
     month=fix(strmid(current,4,2))
     day=fix(strmid(current,6,2))
     hour=fix(strmid(current,9,2))
     minute=fix(strmid(current,11,2))
     second=fix(strmid(current,11,2))
     dates[i]=GREG2JUL(month,day,year,hour,minute,second)
  endfor

  return, dates
end




;PROGRAM: ee_timedist
;PURPOSE:
; 1. Compute length of time of each boxed event from eemouse
; 2. Compute average length of time for all events
; 3. Compute average length of time of event for each observation and plot
; 4. Plot each event against its date such that the size of the dot
; corresponds to the length of the event
; 5. Save plots to a directory of time plots
;PARAMETERS:
;  dat_array=4x100x31 array containing dimension data for event boxes
;  dates=array of Julian dates of each observation
;VARIABLES:
;  depth=number of observations
;  lengths=2D array of lengths of each event in each observation
;  avg_lens=array of average length of time of an event during each
;  observation
;  dev_lens=array of standard deviations of lengths of each event
;  during each observation
;RETURNS: N/A
;SAVES: Plots are saved into a directory containing time plots
;AUTHOR(S): A.E. Bartz, 6/9/17
pro ee_timedist, dat_array, dates

  depth=size(dat_array)
  depth=depth[3]
  lengths=fltarr(100,depth)
  avg_lens=fltarr(depth)
  dev_lens=fltarr(depth)
  
  ;Compute arrays containing each event's length and the average length
  for obs=0,depth-1 do begin
     x0=dat_array[*,0,obs]
     x1=dat_array[*,1,obs]
     ;The absolute value is because some boxes were drawn backwards
     ;(Better to be safe than sorry!)
     lengths[obs]=abs(x1-x0)
     avg_lens[obs]=mean(abs(x1-x0))
     dev_lens[obs]=stddev(abs(x1-x0))
  endfor

  ;Compute & print average length of time for all events
  print, "The average time of an event for all observations is ", mean(avg_lens)
  print, "The standard deviation of time of all observations is ", stddev(avg_lens)

  
end
