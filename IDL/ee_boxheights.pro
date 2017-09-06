;FUNCTION: ee_boxheights
;PURPOSE: convert data set from pixels to real units
;PARAMETERS:
;VARIABLES:
;RETURNS:
;AUTHOR(S): A.E. Bartz 6/20/17

function ee_boxheights, y0, y1, fitshead

  restore, fitshead
;Compute actual heights for y0
  y0=y0*cdelt[1]
  
;Compute actual heights for y1
  y1=y1*cdelt[1]

;Compute differences, stored in arcsec
  diffs=y1-y0
  return, diffs
end
