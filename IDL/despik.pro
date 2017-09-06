;NAME:
;  DESPIK
;PURPOSE:
;  Generalized data despiking tool. Usable for data arrays of 1 to 4 dimensions. 
;CALLING SEQUENCE:
;  result = despik(data [, sigmas=sigmas] [, Niter=Niter])
;INPUT PARAMETERS:
;  data = a data array with 1-4 dimensions.
;OUTPUT:
;  result = processed version of data, with the same structure but spikes removed.
;OPTIONAL KEYWORD INPUTS:
;  sigmas = threshold for designating a bad pixel, as a multiple of the neighborhood 
;     standard deviation. Default = 4.5.
;  Niter = maximum number of iterations for identifying bad pixels. As soon as an
;     iteration fails to identify any new bad pixels, we stop iterating. Default = 10.
;  kernel = convolution kernel used for calculating neighborhood mean and standard deviation.
;     The kernel does not need to be normalized. Default kernels are defined for any number 
;     of dimensions from 1 to 4; these have uniform weight over an 11, 9x9, 5x5x5, or 
;     3x3x3x3 element kernel, respectively.
;  min_std = minimum value for the local standard deviation. This prevents excessive
;     bad pixel detection in areas where the image is very flat due to thresholding or
;     overscan regions. Default = 1.
;  silent = If set, suppress verbose output.
;  mode = Set to detec "bright" spikes, "dark" spikes, or "both". Default is "bright".
;OPTIONAL KEYWORD OUTPUTS:
;  goodmap = map of good pixels. This is a floating point array with the same dimensions
;     as data. Good pixels are 1.0, bad are 0.0.
;ALGORITHM:
;  Bad pixels are identified iteratively based on their excess above a neighborhood
;  mean, measured in standard deviations. The neighborhood
;  mean and standard deviation are taken only over good pixels, which
;  necessitates an iterative approach. 
;  Note: DESPIK could be much faster if we had a well-written, n-dimensional 
;  FFT convolution routine.
;MODIFICATION HISTORY:
;  2013-Nov-27  C. Kankelborg
;  2016-12-8 J. Parker  Added restore functionality if goodmap has
;  already been generated on a previous run

function despik, data, sigmas=sigmas, Niter=Niter, kernel=kernel, min_std=min_std, $
   silent=silent, goodmap=goodmap, mode=mode, restore=restore

if not keyword_set(silent) then begin 
   print, systime()+' DESPIK started on array of ', n_elements(data),' elements.'
   print, 'Step (1): Iteratively identifying bad pixels.'
endif

;Deal with NaN and Inf.
where_bad = where(~finite(data))
if where_bad[0] ne -1 then begin
   bad_crap = data(where_bad)
   data(where_bad) = 1e-6 ;a small number << 1 DN. I am assuming this is harmless!
endif
;I'll replace the bad crap at the end!


;Assess data size & dimensionality. Account for up to 4D.
isize = size(data)
Ndim = isize[0]
t_begin = systime(/seconds)


;Keyword defaults.
if not keyword_set(sigmas) then sigmas = 4.5
if not keyword_set(Niter) then Niter = 10
if not keyword_set(min_std) then min_std = 1.0
if not keyword_set(mode) then mode='bright'
if not keyword_set(kernel) then begin
   case Ndim of
      1: kernel = replicate(1.0, 11)
      2: kernel = replicate(1.0, 9, 9)
      3: kernel = replicate(1.0, 5, 5, 5)
      4: kernel = replicate(1.0, 3, 3, 3, 3)
      else: message,'Data dimensionality is too great. Cannot construct kernel.'
   endcase
endif


;If goodmap exists then skip identifying through restore keyword.
if not keyword_set(restore) then begin


;Identify bad pixels
goodmap = data*0.0 + 1.0 ;Map of good pixels. An array same size as data, initially all 1's
for i=1, Niter do begin
   neighborhood_mean = convol(goodmap*data, kernel, /edge_truncate) / $
                       convol(goodmap,      kernel, /edge_truncate)
   case mode of
      'bright': deviation = data - neighborhood_mean      ; find bright spikes only.
      'dark':   deviation = neighborhood_mean - data      ; find dark spikes only.
      'both':   deviation = abs(data - neighborhood_mean) ; find both bright and dark spikes.
      else: message, 'Called with undefined mode: '+string(mode)
   endcase
   neighborhood_std = sqrt( convol(goodmap*deviation^2, kernel, /edge_truncate) / $
                            convol(goodmap,             kernel, /edge_truncate) ) > min_std
   bad = where( deviation gt (sigmas * neighborhood_std) )
   if bad[0] eq -1 then break
   newly_bad = where( goodmap[bad] )
   if newly_bad[0] eq -1 then break
   if not keyword_set(silent) then begin
      print, i, n_elements(bad), n_elements(newly_bad), $
         format='("Iteration ",i4," found ",i12," bad pixels, ",i12," of them new.")'
      ;print,'Iteration ',i,' found ',n_elements(newly_bad),' newly bad pixels, ', $
      ;   n_elements(bad),' total bad pixels.'
   endif
   goodmap[bad[newly_bad]] = 0.0
endfor

endif 

if not keyword_set(silent) then print,'Step (2): Replacing bad pixels'

;Construct kernel k2 of the form exp(-r)/(1+r^Ndim). This will be used to construct
;very-near-local smoothed version of data. It is just like the neighborhood_mean above,
;except that the kernel is heavily weighted toward the nearest (good) pixels.
Nk2 = 5 ;size of very-near-local smoothing kernel
middle = (Nk2-1)/2
case Ndim of
   1: begin
         k2 = fltarr(Nk2)
         for i=0, Nk2-1 do begin
            x = i - middle
            k2[i] = exp(-abs(x))
         endfor 
      end
   2: begin
         k2 = fltarr(Nk2,Nk2)
         for i=0, Nk2-1 do begin
            x = i - middle
               for j=0, Nk2-1 do begin
                  y = j - middle
                  r = sqrt(x^2 + y^2)
                  k2[i,j] = exp(-r)/(1+r^Ndim)
               endfor
         endfor 
      end
   3: begin
         k2 = fltarr(Nk2,Nk2,Nk2)
         for i=0, Nk2-1 do begin
            x = i - middle
               for j=0, Nk2-1 do begin
                  y = j - middle
                     for k=0, Nk2-1 do begin
                        z = k - middle
                        r = sqrt(x^2 + y^2 + z^2)
                        k2[i,j,k] = exp(-r)/(1+r^Ndim)
                     endfor
               endfor
         endfor 
      end
   4: begin
         k2 = fltarr(Nk2,Nk2,Nk2)
         for i=0, Nk2-1 do begin
            x = i - middle
               for j=0, Nk2-1 do begin
                  y = j - middle
                     for k=0, Nk2-1 do begin
                        z = k - middle
                           for m=0, Nk2-1 do begin
                              t = m - middle
                              r = sqrt(x^2 + y^2 + z^2 + t^2)
                              k2[i,j,k,m] = exp(-r)/(1+r^Ndim)
                           endfor
                     endfor
               endfor
         endfor 
      end
   else: message,'Data dimensionality is too great. Cannot construct k2.'
endcase

;We now re-use the neighborhood_mean array to conserve memory!
neighborhood_mean = convol(goodmap*data, k2, /edge_truncate) / $
                    convol(goodmap,      k2, /edge_truncate)


;Replace bad pixels
bad = where(~goodmap)
result = data
if bad[0] ne -1 then result[bad] = neighborhood_mean[bad]

;Restore the bad crap that was filtered out of the data when we started. Also put the
;bad crap into the result.
if where_bad[0] ne -1 then begin
   data[where_bad] = bad_crap
   result[where_bad] = bad_crap
endif

t_end = systime(/seconds)
if not keyword_set(silent) then print,systime()+' DESPIK finished, ',t_end-t_begin,' sec elapsed.'
return, result

end
