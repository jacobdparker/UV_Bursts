pro hale_final

; Requires use of eerestore before hand
  
  common widget_environment, img, didx, tidx, mouseread
  common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map, goodmap
  common data, rasterindex,rasterdata,sjiindex,sjidata,si_1403_index, si_1403_data,fe_index,fe_data


  iris_orbitvar_corr_l2_old,rasterfile,lambda_shift,nuv_shift,date_obs

;Set up wavelength axis
  raster_size= size(si_1403_data)
  wavemin = si_1403_index[0].wavemin
  wavemax = si_1403_index[0].wavemax
  wavesz = raster_size[1]
  lambda = wavemin + si_1403_index[0].cdelt1*findgen(si_1403_index[0].naxis1) ;wavelength axis, Angstroms
  lambda0 = si_1403_index.wavelnth ;central wavelength for Si IV.
  lambda0 = reform(lambda0,1,1,raster_size[3])
  lambda0 = rebin(lambda0,raster_size[1],1,raster_size[3])
  lambda = rebin(lambda,raster_size[1],1,raster_size[3])
  lambda_shift = reform(lambda_shift,1,1,raster_size[3])
  lambda_shift = rebin(lambda_shift,raster_size[1],1,raster_size[3])
  lambda -= lambda_shift
  c = 3e5                                     ;speed of light, km/s
  velocity = c * (lambda - lambda0)/lambda0   ;velocity axis, km/s

;Set up slit posistion
  slit_position_axis = findgen(raster_size[2])/max(findgen(raster_size[2]))*rasterindex[0].fovy
  slit_position_axis -= mean(slit_position_axis)
  slit_position_axis += rasterindex[0].ycen


;Set up time axis
  time_axis = rasterindex.time/3600+12.5

  
;Start with event 16
  ee_event = 16
  x0 = mouseread.x0[ee_event]
  x1 = mouseread.x1[ee_event]
  y0 = mouseread.y0[ee_event]
  y1 = mouseread.y1[ee_event]
  

;Determine the extent of the spectral domain
  vel_plus = min(where(velocity[*,0,0] ge 300))
  vel_minus = max(where(velocity[*,0,0] le -300))

;Carve out event
  ee16 = si_1403_data[vel_minus:vel_plus,y0:y1,x0:x1]
  ee16sz = size(ee16,/structure)
  ee16_vel = velocity[vel_minus:vel_plus,0,x0:x1]

;Do some gaussian fitting for every spectral line of 1403
  g = ee16*0
  fit = fltarr(9,ee16sz.dimensions[1],ee16sz.dimensions[2])
  fit_chi2 = fltarr(ee16sz.dimensions[1],ee16sz.dimensions[2])

  for i = 0,y1-y0-1 do begin
     for j = 0,x1-x0-1 do begin
        ;; print,'[i,j]',i,',',j
        if total(ee16[*,i,j]) eq 0 then begin
           g[0,i,j] = fltarr(ee16sz.dimensions[0])
           fit[0,i,j] = fltarr(9)
        endif else begin
           if max(ee16[*,i,j]) lt 20 then begin
              g[0,i,j] = fltarr(ee16sz.dimensions[0])
              fit[0,i,j] = fltarr(9)
           endif else begin
              g[0,i,j] = gauss_fit(ee16_vel[*,0,j],ee16[*,i,j],a,/no_back,chi2 = chi2)
              fit[0,i,j] = a
              fit_chi2[i,j] = chi2
              if abs(a[4]) ge 200 then begin
                 g[0,i,j] = fltarr(ee16sz.dimensions[0])
                 fit[0,i,j] = fltarr(9)
              endif
              if abs(a[4]) lt 200 gt 100 then begin
       
                 plot,ee16_vel[*,*,j],ee16[*,i,j],psym=2
                 oplot,ee16_vel[*,*,j],g[*,i,j]
                 STOP
              endif
           endelse
        endelse
     end
  end

;Velocity Map Plot



  doppler_shifts = reform(fit[4,*,*],ee16sz.dimensions[1],ee16sz.dimensions[2])
  doppler_shifts = transpose(doppler_shifts)
  velo_map = image(doppler_shifts,title='Doppler Map',axis_style=1,xtitle='Time (exposure count)',ytitle='Slit Position (pixels)',margin=0.1,dimensions=[1024,512])
  velo_map.rgb_table = colortable(70,/reverse)
  velo_map.max_value = 100
  velo_map.min_value = -100
  
  cb = colorbar(target = velo_map,title='Doppler Shift (km/s)',orientation=1)

  chi2_trans = transpose(fit_chi2)
  fit_quality = contour(sqrt(chi2_trans),/current,/overplot,color='black',c_label_show=0,dimensions=[1024,512])
  fit_quality.min_value = 1
  fit_quality.n_levels=4

;Look at further wavelength calibration
  ;; velocity-= mean(total(doppler_shifts[*,0:10],2)/11)
  doppler_shifts[where(doppler_shifts eq 0)] = mean(total(doppler_shifts[*,0:10],2)/11)
  doppler_shifts -= mean(total(doppler_shifts[*,0:10],2)/11)
  velo_map_cal = image(doppler_shifts,title='Normalized Doppler Map',axis_style=1,xtitle='Time (exposure count)',ytitle='Slit Position (pixels)',margin=0.1,dimensions=[1024,512])
  velo_map_cal.rgb_table = colortable(70,/reverse)
  velo_map_cal.max_value = 100
  velo_map_cal.min_value = -100
  cb = colorbar(target = velo_map_cal,title='Doppler Shift (km/s)',orientation=1)
 
 
;Refine fitting
  g = ee16*0
  fit = fltarr(9,ee16sz.dimensions[1],ee16sz.dimensions[2])
  fit_chi2 = fltarr(ee16sz.dimensions[1],ee16sz.dimensions[2])
  

  for i = 0,y1-y0-1 do begin
     for j = 0,x1-x0-1 do begin
        ;; print,'[i,j]',i,',',j
        if total(ee16[*,i,j]) eq 0 then begin
           g[0,i,j] = fltarr(ee16sz.dimensions[0])
           fit[0,i,j] = fltarr(9)
        endif else begin
           if max(ee16[*,i,j]) lt 20 then begin
              g[0,i,j] = fltarr(ee16sz.dimensions[0])
              fit[0,i,j] = fltarr(9)
           endif else begin
              a=0
              g[0,i,j] = gauss_fit(ee16_vel[*,0,j],ee16[*,i,j],a,/no_back,chi2 = chi2,double=0)
              fit[0,i,j] = a
              fit_chi2[i,j] = chi2
              
              if chi2 gt 1e5 then begin
                 a=0
                 g[0,i,j] = gauss_fit(ee16_vel[*,0,j],ee16[*,i,j],a,/no_back,chi2 = chi2_double,double=1)
                 fit[0,i,j] = fltarr(9)
                 fit[0,i,j] = a

                 if abs(a[7]) gt 60 then begin
                    a=0
                    g[0,i,j] = gauss_fit(ee16_vel[*,0,j],ee16[*,i,j],a,/no_back,chi2 = chi2,double=0)
                    fit[0,i,j] = fltarr(9)
                    fit[0,i,j] = a
                    fit_chi2[i,j] = chi2
                    
                 endif else fit_chi2[i,j] = chi2_double
                 
                 if chi2 lt chi2_double then begin
                    a=0
                    g[0,i,j] = gauss_fit(ee16_vel[*,0,j],ee16[*,i,j],a,/no_back,chi2 = chi2,double=0)
                    fit[0,i,j] = fltarr(9)
                    fit[0,i,j] = a
                    fit_chi2[i,j] = chi2
                    
                 endif else fit_chi2[i,j] = chi2_double
                 
                   
              endif
              
              if abs(a[4]) ge 200 then begin
                 g[0,i,j] = fltarr(ee16sz.dimensions[0])
                 fit[0,i,j] = fltarr(9)
              endif
              if abs(a[4]) lt 200 gt 100 then begin
       
                 plot,ee16_vel[*,*,j],ee16[*,i,j],psym=2
                 oplot,ee16_vel[*,*,j],g[*,i,j]
                 STOP
              endif
              a=0
           endelse
        endelse
     end
  end

  ;; doppler_shifts = reform(fit[4,*,*],ee16sz.dimensions[1],ee16sz.dimensions[2])
  ;; doppler_shifts = transpose(doppler_shifts)
  ;; velo_map2 = image(doppler_shifts,margin=0)
  ;; velo_map2.rgb_table = colortable(70,/reverse)
  ;; velo_map2.max_value = 100
  ;; velo_map2.min_value = -100
  ;; cb2 = colorbar(target = velo_map2,title='Doppler Shift')

  ;; chi2_trans = transpose(fit_chi2)
  ;; fit_quality2 = contour(sqrt(chi2_trans),/current,/overplot,color='black',c_label_show=0)
  ;; fit_quality2.min_value = 1

  doppler_shifts = reform(fit[7,*,*],ee16sz.dimensions[1],ee16sz.dimensions[2])
  doppler_shifts = transpose(doppler_shifts)
  doppler_shifts[where(doppler_shifts eq 0)] = mean(total(doppler_shifts[*,0:10],2)/11)
  doppler_shifts -= mean(total(doppler_shifts[*,0:10],2)/11)
  velo_map3 = image(doppler_shifts[150:-1,*],indgen(n_elements(doppler_shifts[150:-1,0]))+150,indgen(y1-y0+1),title='(b)',layout=[2,1,2],xtitle='Time (exposure count)',ytitle='Slit Position (pixels)',margin=0.1,axis_style=1,dimensions=[1024,512])
  velo_map3.rgb_table = colortable(70,/reverse)
  velo_map3.max_value = 100
  velo_map3.min_value = -100
  
  ;; cb3 = colorbar(target = velo_map3,title='Doppler Shift')

  doppler_shifts = reform(fit[4,*,*],ee16sz.dimensions[1],ee16sz.dimensions[2])
  doppler_shifts = transpose(doppler_shifts)
  doppler_shifts[where(doppler_shifts eq 0)] = mean(total(doppler_shifts[*,0:10],2)/11)
  doppler_shifts -= mean(total(doppler_shifts[*,0:10],2)/11)
  velo_map4 = image(doppler_shifts[150:-1,*],indgen(n_elements(doppler_shifts[150:-1,0]))+150,indgen(y1-y0+1),title='(a)',layout=[2,1,1],/current,xtitle='Time (exposure count)',ytitle='Slit Position (pixels)',margin=0.1,axis_style=1,dimensions=[1024,512])
  velo_map4.rgb_table = colortable(70,/reverse)
  velo_map4.max_value = 100
  velo_map4.min_value = -100
  cb4 = colorbar(target = velo_map3,title='Doppler Shift (km/s)',orientation=1)

;Panel of spectral lines at peak time
  Time = 279
  peak_time = rasterindex[time].date_obs
  xr = [-100,100]
  n=floor(y1-y0)/4.
  ;oplot fits
  color = 'red'

  

  t0 = 5
  line_plot_win = window()
  for i = 0,2 do begin
     for j = 0,3 do begin
        plot_number=(i+1)+3*(j)
        line_plot = plot(velocity[*,*,time+(i-1)*t0],si_1403_data[*,y0+j*n,time+(i-1)*t0],layout =[3,4,plot_number],xr=xr,/current,xtitle='km/s',ytitle='Intensity',title = rasterindex[time+(i-1)*t0].date_obs+', y='+strtrim(string(round(j*n)),1))
        line_plot = plot(ee16_vel[*,*,time+(i-1)*t0-x0],g[*,j*n,time+(i-1)*t0-x0],xr=xr,color=color,/overplot)
        line_plot.yr=[0,max(si_1403_data[*,y0+j*n,time+(i-1)*t0])]
        
     end
  end
  

 
;optical depth plot
  dplot_win = window()

  raster_size= size(rasterdata)
  wavemin = rasterindex[0].wavemin
  wavemax = rasterindex[0].wavemax
  wavesz = raster_size[1]
  lambda_1394 = wavemin + rasterindex[0].cdelt1*findgen(rasterindex[0].naxis1) ;wavelength axis, Angstroms
  lambda0 = rasterindex.wavelnth ;central wavelength for Si IV.
  lambda0 = reform(lambda0,1,1,raster_size[3])
  lambda0 = rebin(lambda0,raster_size[1],1,raster_size[3])
  lambda_1394 = rebin(lambda_1394,raster_size[1],1,raster_size[3])
  
  lambda_1394 -= lambda_shift
  velocity_1394 = c * (lambda_1394 - lambda0)/lambda0 ;velocity axis, km/s

 
  

  
  for i = 0,2 do begin
     for j = 0,3 do begin
        plot_number=(i+1)+3*(j)
        ;; interp_1394 = interpol(rasterdata[*,y0+j*n,time+(i-1)*t0],velocity_1394[*,*,time+(i-1)*t0],velocity[*,*,time+(i-1)*t0])
        ;; line_difference = 2*si_1403_data[*,y0+j*n,time+(i-1)*t0]-interp_1394
        ;; line_difference /= interp_1394
        ;; dplot = plot(velocity[*,*,time+(i-1)*t0],line_difference,layout =[3,4,plot_number],xr=xr,/current,title=string(plot_number))

        dplot = plot(velocity[*,*,time+(i-1)*t0],2*si_1403_data[*,y0+j*n,time+(i-1)*t0],/current,layout=[3,4,plot_number],xtitle='km/s',ytitle='Intensity',title = rasterindex[time+(i-1)*t0].date_obs+', y='+strtrim(string(round(j*n)),1))
        dplot = plot(velocity_1394[*,*,time+(i-1)*t0],rasterdata[*,y0+j*n,time+(i-1)*t0],color='green',/overplot,/current)

        dplot.xr = [-100,100]
        dplot.yr = [0,max(rasterdata[*,y0+j*n,time+(i-1)*t0])]
       
     end
  end
  
  
  
 
  
 STOP
  
end
