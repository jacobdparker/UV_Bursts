;NAME:
;  LINEWIDTH_FIGURE
;PURPOSE:
;  Create high quality figure of spectral line width and intensity,
;  using a 2D legend.
;CALLING SEQUENCE:
;  LINEWIDTH_FIGURE, WIDTHS, INTENSITIES [, IMAGE=IMAGE][, LEGEND=LEGEND][, EPSFILE=EPSFILE]
;
;HISTORY:
;  2014-Jul-29  C. Kankelborg and H. Alpert


;**********************************
;*  COLOR TRANSLATION SUBROUTINE  *
;**********************************
;This subroutine translates 2 equal-sized images (widths, intensities) to
;a tri-color image,  using a nifty 2D color table. Optional keywords 
;W_max and I_max specify maximum displayed values of width and intensity, 
;respectively.
;Code by Hannah Alpert & Charles Kankelborg, 2014-Jul-29.
function width_colormap, widths, intensities, W_max=W_max, I_max=I_max  ;CCK came up with more descriptive name.

if not keyword_set(W_max) then W_max=max(widths)
if not keyword_set(I_max) then I_max=max(intensities)

Nx = n_elements(widths[0,*])
Ny = n_elements(widths[*,0])

R_array = fltarr(Nx,Ny) ;CCK fltarr rather than findgen
G_array = fltarr(Nx,Ny)
B_array = fltarr(Nx,Ny)

;boundary=W_max/2.0 ;CCK no longer needed

;CCK produce normalized intensity and width arrays, and threshold at I_max & W_max!
I = (intensities < I_max)/I_max
W = (     widths < W_max)/W_max

;CCK calculate RGB arrays without for loops --- Hannah's scaling
;R_array = 127.5 * I * ( 1.0 + (W-0.5) )
;G_array = 127.5 * I * ( 1.0 - (W-0.5) )
;B_array = R_array
;Note that the factor in outermost parentheses has range of 0.5 to 1.5. This prevents reaching extremes of the color scale.
;Moreover, the normalization prevents any of the channels from reaching more than 3/4 of 255.

; --> CCK proposed scaling:
R_array = 255.0 * I * W
G_array = 255.0 * I * (1.0 - W)
B_array = R_array

;for r=0, n_elements(widths[*,0])-1 do begin    ;CCK note: the formulas are the same regardless of the if statement!
;    for s=0, n_elements(widths[0,*])-1 do begin
;        if widths[r,s] lt boundary then begin
;            R_array[r,s] = 127.5*intensities[r,s]/I_max - (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(-127.5)
;            G_array[r,s] = 127.5*intensities[r,s]/I_max - (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(127.5)
;            B_array[r,s] = 127.5*intensities[r,s]/I_max - (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(-127.5)
;        endif else begin
;            R_array[r,s] = 127.5*intensities[r,s]/I_max + (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(127.5)
;            G_array[r,s] = 127.5*intensities[r,s]/I_max + (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(-127.5)
;            B_array[r,s] = 127.5*intensities[r,s]/I_max + (intensities[r,s]/I_max)*((widths[r,s]-boundary)/W_max)*(127.5)        
;        endelse
;    endfor
;endfor

image = [[[R_array]],[[G_array]],[[B_array]]]
return, byte( round(image) <255 >0 ) ;CCK round to integer and reduce to 8 bits deep.

end



;*****************************************
;*        M A I N   P R O G R A M        *
;*****************************************

pro linewidth_figure, widths, intensities, image=image, legend=legend, epsfile=epsfile, $
   W_max=W_max, I_max=I_max
if not keyword_set(W_max) then W_max = max(abs(widths))
if not keyword_set(I_max) then I_max = max(intensities)

image = width_colormap(widths, intensities,  W_max=W_max, I_max=I_max)

;Create legend image
Nlegend = 256 ;Size of legend image (square)
width_axis = W_max * findgen(Nlegend)/(Nlegend-1)
legend_widths = width_axis # replicate(1.0, Nlegend)
intensity_axis = I_max * findgen(Nlegend)/(Nlegend-1)
legend_intensities = replicate(1.0, Nlegend) # intensity_axis
legend = width_colormap(legend_widths, legend_intensities, W_max=W_max, I_max=I_max)

;Optionally create .eps figures
if keyword_set(epsfile) then begin
   set_plot,'ps'
   
   ;Create legend .eps file
   device, filename=epsfile+'_legend.eps'
   plot, width_axis, legend_axis, /nodata, xtitle='Width (km/s)', ytitle='Intensity (dn)', $
      /xstyle, /ystyle, charsize=2.0, ticklen=-0.02
   tv, legend, 0, 0, xsize=W_max, ysize=I_max, true=3, /data
   plot, width_axis, legend_axis, /nodata, xtitle='Width (km/s)', ytitle='Intensity (dn)', $
      /xstyle, /ystyle, charsize=2.0, ticklen=-0.02, /noerase
   device, /close
   
   ;Create figure .eps file
   device, filename=epsfile+'.eps'
   plot, [0, width_s], [0, height_km], /nodata, xtitle='t (s)', ytitle='y (km)', $
      /xstyle, /ystyle, charsize=2.0, ticklen=-0.02
   tv, image, 0, 0, xsize = width_s, ysize=height_km, true=3, /data
   plot, [0, width_s], [0, height_km], /nodata, xtitle='t (s)', ytitle='y (km)', $
      /xstyle, /ystyle, charsize=2.0, ticklen=-0.02, /noerase
   device,/close
    
endif

end