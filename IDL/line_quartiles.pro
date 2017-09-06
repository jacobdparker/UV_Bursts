;+
;NAME:
;  LINE_QUARTILES
;PURPOSE:
;  Characterize a spectral line profile (or any binned distribution)
;  using quartiles that are interpolated within the bins.
;CALLING SEQUENCE:
;  quartiles = LINE_QUARTILES(data [, x])
;INPUTS:
;  data = A 1D array corresponding to a tabulated, non-normalized distribution  
;     of some sort (e.g., a spectral line profile).
;  x = A 1D array of the same size as data, giving the coordinates of 
;     the data values.
;OUTPUT:
;  The result is an array of quartiles. If the coordinate x is given, then
;  they are x-values. If not, they are (non-integer) index values.
;OPTIONAL KEYWORDS:
;  spline, quadratic, lsquadratic, nan (all passed through to INTERPOL).
;MODIFICATION HISTORY:
;  2014-Jun-27  C. Kankelborg (fixed offset bug)
;-
function line_quartiles, data, x, spline=spline, $
   quadratic=quadratic, lsquadratic=lsquadratic, nan=nan

dsize = size(data)
if dsize[0] ne 1 then message,'Input is not a 1D array. Exiting.'
N = dsize[1] ;number of array elements.

cdf = total(data,/cumulative)
cdf /= cdf[N-1]
if n_elements(x) ne N then x = findgen(N) ;coordinate along the array
dx = x[1] - x[0] ;assuming uniform spacing!
quartiles = 0.5*dx + interpol(x, cdf, [0.25, 0.5, 0.75], spline=spline, $
   quadratic=quadratic, lsquadratic=lsquadratic, nan=nan)

return, quartiles
end