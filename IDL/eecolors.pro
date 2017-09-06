;NAME:
;  eecolors
;
;PURPOSE:
;; Take an ee.sav file and map line profile shape with some
;; interesting color profile

;CALLING SEQUENCE:
;  eecolors, ee_event
;INPUT PARAMETERS:
;
;  ee_event
;
;KEYWORDS:
;  
;MODIFICATION HISTORY:


pro eecolors,ee_event=ee_event, single=single,event_color=event_color,noplot=noplot

w = getwindows()
  if n_elements(w) gt 1 then begin
     for i = 0,n_elements(w)-1 do w(i).close
  endif
  
  common widget_environment, img, didx, tidx, mouseread
  common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map
  common data, rasterindex,rasterdata,sjiindex,sjidata

 

  raster_size= size(rasterdata)
  
  wavemin = rasterindex[0].wavemin
  wavemax = rasterindex[0].wavemax
  wavesz = raster_size[1]
  lambda = wavemin + rasterindex[0].cdelt1*findgen(rasterindex[0].naxis1)
   ;wavelength axis, Angstroms
lambda0 = rasterindex.wavelnth  ;central wavelength for Si IV.
c = 3e5 ;speed of light, km/s
velocity = c * (lambda - lambda0)/lambda0 ;velocity axis, km/s

explosive_threshold = 60.0      ;km/s. SiIV has T=10^4.8, c_s = 40 km/s.
doppler_max = 300 ;km/s avoiding integrating over adjacent spectral lines

vel_max = abs(velocity) lt doppler_max
blue_vel = velocity lt -explosive_threshold
red_vel = velocity gt explosive_threshold



blue_vel = where(vel_max+blue_vel eq 2)
red_vel = where(vel_max+red_vel eq 2)


blue = fltarr(raster_size[3],raster_size[2])
red = blue
green = red



for i=0,raster_size(3)-1 do begin

   blue(i,*)= total(rasterdata[blue_vel,*,i],1)
   red(i,*) = total(rasterdata[red_vel,*,i],1)
   green(i,*) = total(rasterdata[where(abs(velocity) lt explosive_threshold),*,i],1)
end




ee_count = mouseread.count
  x0 = mouseread.x0[0:ee_count]
  x1 = mouseread.x1[0:ee_count]
  y0 = mouseread.y0[0:ee_count]
  y1 = mouseread.y1[0:ee_count]

  im = make_array(raster_size(3),raster_size(2),3)
  
  if keyword_set(single) then begin
     i = ee_event
     im(x0[i],y0[i],0) = red[x0[i]:x1[i],y0[i]:y1[i]]
     im(x0[i],y0[i],1) = green[x0[i]:x1[i],y0[i]:y1[i]]
     im(x0[i],y0[i],2) = blue[x0[i]:x1[i],y0[i]:y1[i]]
     event_color = im(x0[i]:x1[i],y0[i]:y1[i],*)
     event_sz = size(event_color)

     if keyword_set(noplot) then begin

     endif else begin
        img = image(event_color,margin=0,dimensions=[event_sz(1),event_sz(2)] )
     endelse
     
  endif else begin
     
        

for i = 0,ee_count do begin

   im(x0[i],y0[i],0) = red[x0[i]:x1[i],y0[i]:y1[i]]
   im(x0[i],y0[i],1) = green[x0[i]:x1[i],y0[i]:y1[i]]
   im(x0[i],y0[i],2) = blue[x0[i]:x1[i],y0[i]:y1[i]]
   

 endfor

img = image(im,dimensions=[1600,900],pos = [.01,.01,.99,.99])
endelse
     


;;  time = x1-x0
  
;; for i = 0,time-1 do begin
   
;;    ;; con = surface(rasterdata[*,y0:y1,x0+i],/current)
;;    ;; con.refresh,/disable
;;    ;; con.rotate,/reset
;;    ;; con.rotate,-90, /xaxis
;;    ;; con.xr = [linecenter-20,linecenter+20]
   
;;    ;; con.refresh
;;    surface,rasterdata[*,y0:y1,x0+i],velocity,[y0:y1],xr=[-100,100]
;;    wait,.125
;;    ;con.erase
   
;; end

  
end
