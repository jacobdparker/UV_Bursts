

common widget_environment, img, didx, tidx, mouseread
common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map, goodmap
common data, rasterindex,rasterdata,sjiindex,sjidata

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EVENT Map with Boxes Figure ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
;; map_sz= size(siiv_ee_map)
;; i = image(siiv_ee_map>100<1000,dimensions=[map_sz(1),map_sz(2)],margin=0)




;; if mouseread.count gt 0 then begin
;;    ;add a standard box color for comparison with eemovie
;;    mouseread.color=round(findgen(mouseread.count)/(mouseread.count)*254)+1
;;      for i=0,mouseread.count-1 do begin
;;         boxes= plot( [mouseread.x0[i], mouseread.x1[i], $
;;                mouseread.x1[i], mouseread.x0[i], mouseread.x0[i]],$
;;               [mouseread.y0[i], mouseread.y0[i], $
;;                mouseread.y1[i], mouseread.y1[i], mouseread.y0[i]],$
;;                rgb_table=25,vert_colors=mouseread.color[i],thick=1.5,/overplot,/current)
;;         event_number = text(mouseread.x1[i],mouseread.y1[i],string(i, format='(I4)'),/current,/overplot,font_color="white",/data,font_size=6)
;;         ;-mouseread.y0[i])/2+mouseread.y0[i]-1
;;      endfor
     
;;   endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EE Color Map for certain event ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event = 24
eecolors,ee_event=event,/single,event_color=event_color



raster_size= size(rasterdata)
  
wavemin = rasterindex[0].wavemin
wavemax = rasterindex[0].wavemax
wavesz = raster_size[1]
lambda = wavemin + rasterindex[0].cdelt1*findgen(rasterindex[0].naxis1)
   ;wavelength axis, Angstroms
lambda0 = rasterindex.wavelnth  ;central wavelength for Si IV.
c = !CONST.c / 1000 ;speed of light, km/s
velocity = c * (lambda - lambda0)/lambda0 ;velocity axis, km/s

;interesting portion of color plot
pos = [115,26,220,38]

a = 7
b = 24
c = 45
d = 85

box = plot( [pos(0),pos(0),pos(2),pos(2),pos(0)],[pos(1),pos(3),pos(3),pos(1),pos(1)],thick = 1.5, color ='white',/current,/overplot)

marks = plot( [pos(0)+a,pos(0)+a],[pos(1),pos(1)-3], thick = 1, color = 'white', /current,/overplot)
letter = text( pos(0)+a, pos(1)-10,'a',/data,font_color='white',font_size = 4)

marks = plot( [pos(0)+b,pos(0)+b],[pos(1),pos(1)-3], thick = 1, color = 'white', /current,/overplot)
letter = text( pos(0)+b, pos(1)-10,'b',/data,font_color='white',font_size = 4)

marks = plot( [pos(0)+c,pos(0)+c],[pos(1),pos(1)-3], thick = 1, color = 'white', /current,/overplot)
letter = text( pos(0)+c, pos(1)-10,'c',/data,font_color='white',font_size = 4)

marks = plot( [pos(0)+d,pos(0)+d],[pos(1),pos(1)-3], thick = 1, color = 'white', /current,/overplot)
letter = text( pos(0)+d, pos(1)-10,'d',/data,font_color='white',font_size = 4)

line = rasterdata(*,mouseread.y0[event]:mouseread.y1[event],mouseread.x0[event]:mouseread.x1[event])
tline = total(line[*,pos(1):pos(3),pos(0):pos(2)],2)

;; for i=0,n_elements(tline(0,*))-1 do begin
;;    plot,velocity,tline(*,i),xr=[-200,200],yr=[0,max(tline)]
;;    wait,.2
;; end

ap=plot(velocity,tline(*,a),xr = [-200,200],name='a',xtitle='Doppler Velocity',ytitle='Intensity (Arbitrary Units)',title='Line Profile Evolution')
bp=plot(velocity,tline(*,b),xr = [-200,200],/overplot,color='red',name='b') 
cp=plot(velocity,tline(*,c),xr = [-200,200],/overplot,color='blue',name='c')
dp=plot(velocity,tline(*,d),xr = [-200,200],/overplot,color='green',name='d')
leg = legend(target = [ap,bp,cp,dp],pos = [105,10000],/data,/auto_text_color)
ap.yr=[0,12000]

end
