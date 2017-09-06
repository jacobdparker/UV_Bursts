;+
;NAME:
;  FUV_BG_MODEL
;PURPOSE:
;  Since IRIS SG FUV darks are currently not very accurate, this routine is
;  designed to statistically infer a dark background and subtract it.
;  Conceptually, we expect at least half of the pixels in any FUV SG data cube
;  to be at or near the dark level. So, we use the 25th percentile in
;  each row as an indication of the dark level for that row. Note that there
;  is a significant step in the dark level, which is captured by going row
;  by row.  This routine does not attempt to get at horizontal
;  variation of the darks. It is well suited to individual spectral
;  windows, such as would be extracted from L2 data in the example below.
;CALLING SEQUENCE:
;  bg = fuv_bg_model(data [, /replace] [, percentile=percentile])
;EXAMPLE:
;  read_iris_l2, rastfile, index, data, wave = 'Si IV'
;  bg = fuv_bg_model(data, /replace)
;RESULT:
;  The output is an image of estimated detector background (dark signal).
;OPTIONAL KEYWORD INPUTS:
;  replace = if set, then data cube is replaced by a background
;     subtracted version. Bad data (see below) will be replaced by 0.
;  percentile = the data value percentile that will be taken as the
;     background level in each row. Default = 25. If P percent of the 
;     pixels in the row contain a physically significant signal, then 
;     the optimum value would apparently be percentile = (1-P)/2.
;  bad_data = value used for bad data (typically, data that is outside
;     the actual image in the L2 due to having geometric distortions
;     removed). Default = -200.
;DEPENDENCIES:
;  PRANK
;MODIFICATION HISTORY:
;  2014-May-10  C. Kankelborg
;-
function fuv_bg_model, data, replace=replace, percentile=percentile, bad_data=bad_data
if not keyword_set(percentile) then percentile = 25
if not keyword_set(bad_data) then bad_data = -200

datasize = size(data)
Nlambda = datasize[1]
Ny = datasize[2]
Nt = datasize[3]

bg = fltarr(Nlambda, Ny) ;Storage for background map
for i = 0, Ny-1 do begin
   ss_good = where(data[*,i,*] ne bad_data)
   if ss_good[0] ne -1 then bg[*,i] = prank( (data[*,i,*])[ss_good], percentile )
endfor
if keyword_set(replace) then begin
   ss_bad = where(data eq bad_data)
   for i=0, Nt-1 do begin
      data[*,*,i] = (temporary(data[*,*,i]) - bg)
   endfor
   data[ss_bad] = 0.0
endif

return, bg

end