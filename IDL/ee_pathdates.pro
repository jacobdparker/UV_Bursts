;FUNCTION: ee_pathdates
;PURPOSE: Compute dates of observations from the EE filepath array
;PARAMETERS: files=all filepaths to ee.sav data
;VARIABLES:
;  dates=array of Julian dates for each observation
;  current=string in format "yearmonthday_hourminsec" with 15 characters
;  year, month, day, hour, minute = integers
;RETURNS: array of Julian dates
;AUTHOR(S): A.E. Bartz 6/9/17
function ee_pathdates, files

  n=n_elements(files)
  dates=fltarr(n)
  
  ;Write the dates into array
  for i=0,n-1 do begin
     current=files[i]
     year=strmid(current,11,4)
     month=strmid(current,16,2)
     day=strmid(current,19,2)
     hour=strmid(current,25,2)
     minute=strmid(current,27,2)
     dates[i]=GREG2JUL(month,day,year,hour,minute)
  endfor

  return, dates
end  
  
