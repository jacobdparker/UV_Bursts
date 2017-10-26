;FUNCTION: ee_box_data
;PURPOSE: Make and return array of x0, x1, y0, y1 values for each box in each
;observation
;PARAMETERS:
;  files=all filepaths to ee.sav files containing box data
;VARIABLES:
;  arr=array that contains data of x0, x1, y0, y1
;  vals=temporary array containing box values for each observation
;RETURNS: arr
;AUTHOR(S): A.E. Bartz & J.D. Parker 6/8/17
function ee_box_data, files

  arr=fltarr(100,4,n_elements(files))
  
;Restore files one by one and fill in array with values
;Currently runs in about 28 seconds
  for i=0,n_elements(files)-1 do begin
     restore, files[i]
     arr[0,0,i]=[[mouseread.x0],[mouseread.x1],[mouseread.y0],[mouseread.y1]]
  endfor
     
  return, arr
end
