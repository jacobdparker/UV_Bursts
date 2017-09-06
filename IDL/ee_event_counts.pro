;FUNCTION: ee_event_counts
;PURPOSE: Make and return array containing the total number of boxes drawn
;for all EE observations
;PARAMETERS:
;  files=all filepaths to ee.sav files containing box data
;VARIABLES:
;  n=length of files array
;  counts=integer array containing number of boxes drawn per array
;RETURNS: counts
;AUTHOR(S): A.E. Bartz, 6/9/17
function ee_event_counts, files

;Create filepath and counts arrays
  n=n_elements(files)
  counts=make_array(n)

;Fill counts array
;Currently runs in about 27.5 seconds  
  for i=0,n-1 do begin
     restore, files[i]
     counts[i]=mouseread.count
  endfor
  
  return, counts
end

