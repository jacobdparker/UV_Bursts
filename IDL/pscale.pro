;NAME:
;  PSCALE
;PURPOSE:
;  Threshold an array at lower and upper percentile values.
;CALLING SEQUENCE:
;  result = pscale(data, plo, phi)
;INPUTS:
;  plo = lower percentile threshold
;  phi = upper percentile threshold
;MODIFICATION HISTORY:
;  2013-Aug-26  CCK
;
function pscale, data, plo, phi
thresholds = prank(data, [plo,phi])
result = data > thresholds[0] < thresholds[1]
return,result
end