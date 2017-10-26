;FUNCTION: ee_boxlength
;PURPOSE: compute time length of boxes
;PARAMETERS:
;  x0 = beginning positions of boxes
;  x1 = ending positions of boxes
;  timefile=filepath to a .sav file containing observation time information
;VARIABLES:
;  n=number of arrays with lengths to compute
;  box_len=array of the lengths of boxes drawn in an image
;RETURNS: box_len
;AUTHOR(S): A.E. Bartz 6/14/17

function ee_boxlength, x0, x1, timefile

  restore, timefile

;Compute actual times for x0
  t0=dateobs[x0]
  y0=strmid(t0,0,4)
  m0=strmid(t0,5,2)
  d0=strmid(t0,8,2)
  h0=strmid(t0,11,2)
  mn0=strmid(t0,14,2)
  s0=strmid(t0,17,6)
  t0=GREG2JUL(m0,d0,y0,h0,mn0,s0)
  
;Compute actual times for x1
  t1=dateobs[x1]
  y1=strmid(t1,0,4)
  m1=strmid(t1,5,2)
  d1=strmid(t1,8,2)
  h1=strmid(t1,11,2)
  mn1=strmid(t1,14,2)
  s1=strmid(t1,17,6)
  t1=GREG2JUL(m1,d1,y1,h1,mn1,s1)
;Compute differences, stored as hours
  box_len=(t1-t0)*24
  
return, box_len
end
