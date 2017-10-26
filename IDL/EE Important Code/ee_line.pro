;FUNCTION: ee_calchi
;PURPOSE: calculate chi squared at all times and slit positions for an
;event
;RETURNS: chisq, an array of all of the chi squared values for
;time/position
;CALLING SEQUENCE: ee_calchi(data_1394,data_1403,vel_1394, vel_1403)
;AUTHOR(S): A.E. Bartz, 7/19/17
function ee_calchi, data_1394, data_1403, vel_1394, vel_1403
  sz_1394=size(data_1394)
  sz_1403=size(data_1403)
  n_slit=sz_1394[2]
  n_time=sz_1394[3]
  chisq=fltarr(n_slit,n_time)

  for slit=0,n_slit-1 do begin
     if sz_1394[1] ge sz_1403[1] then begin
        for t=0,n_time-1 do begin
           int=interpol(data_1403[*,slit,t],vel_1403[*,0,t], vel_1394[*,0,t])
           chisq[slit,t]=total((data_1394[*,slit,t]-2*int)^2)
        endfor
     endif else begin
        for t=0,n_time-1 do begin
           int=interpol(data_1394[*,slit,t],vel_1394[*,0,t],vel_1403[*,0,t])
           chisq[slit,t]=total((int-2*data_1403[*,slit,t])^2)
        endfor
     endelse
  endfor

  return, chisq
end

;PROGRAM: ee_line
;PURPOSE: calculate line ratio, plot intensity map of chi squared
;CALLING SEQUENCE: eeline, year, month, day (, index=index,
;event=event)
;MODIFICATION HISTORY:
;  A. E. Bartz 7/25/17
pro ee_line, year, month, day, index=index, event=event

  message, "Locating files...", /information
  if month lt 10 then begin
     if day lt 10 then directory="../EE_Data/"+strcompress(string(year),/remove_all)+"/"+strcompress(string(0),/remove_all)+strcompress(string(month),/remove_all)+"/"+strcompress(string(0),/remove_all)+strcompress(string(day),/remove_all)+"/" else directory="../EE_Data/"+strcompress(string(year),/remove_all)+"/"+strcompress(string(0),/remove_all)+strcompress(string(month),/remove_all)+"/"+strcompress(string(day),/remove_all)+"/"
  endif else begin
     if day lt 10 then directory="../EE_Data/"+strcompress(string(year),/remove_all)+"/"+strcompress(string(month),/remove_all)+"/"+strcompress(string(0),/remove_all)+strcompress(string(day),/remove_all)+"/" else directory="../EE_Data/"+strcompress(string(year),/remove_all)+"/"+strcompress(string(month),/remove_all)+"/"+strcompress(string(day),/remove_all)+"/"
  endelse
 
  boxfile=file_search(directory, "boxes*")
  if not(keyword_set(index)) then index=0
  if n_elements(boxfile) gt 1 then boxfile=boxfile[index]

  eefile=file_search(directory, "ee*20.sav")
  if n_elements(eefile) gt 1 then eefile=eefile[index]

  datfile=file_search(directory, "si_data*")
  if n_elements(datfile) gt 1 then datfile=datfile[index]

  eefiles=file_search("../EE_Data","ee*20.sav")
  for n=0,n_elements(eefiles)-1 do begin
     if eefiles[n] eq eefile then begin
        index=n
        break
     endif
  endfor
  undefine, eefiles

  message, "Restoring data...",/information
  restore, datfile
  restore, eefile
  restore, boxfile
  restore, "ee_interesting.sav"

  message, "Analyzing data...",/information
  if keyword_set(event) then begin
     event-=1
;Define event bounds
     x0=mouseread.x0[event]
     y0=mouseread.y0[event]
     x1=mouseread.x1[event]
     y1=mouseread.y1[event]
;Establish dataset size
     sz_1394=size(si_struct.si_1394_data)
     sz_1403=size(si_struct.si_1403_data)
;Define wavelengths as a three dimensional array     
     lambda0_1394=si_struct.si_1394_index.wavelnth
     lambda0_1394=reform(lambda0_1394,1,1,sz_1394[3])
     lambda0_1394=rebin(lambda0_1394,sz_1394[1],1,sz_1394[3])
     
     lambda0_1403=si_struct.si_1403_index.wavelnth
     lambda0_1403=reform(lambda0_1403,1,1,sz_1403[3])
     lambda0_1403=rebin(lambda0_1403,sz_1403[1],1,sz_1403[3])

     lambda_1394=si_struct.si_1394_index[0].wavemin+si_struct.si_1394_index[0].cdelt1*findgen(si_struct.si_1394_index[0].naxis1)
     lambda_1394=rebin(lambda_1394,sz_1394[1],1,sz_1394[3])
     
     lambda_1403=si_struct.si_1403_index[0].wavemin+si_struct.si_1403_index[0].cdelt1*findgen(si_struct.si_1403_index[0].naxis1)
     lambda_1403=rebin(lambda_1403,sz_1403[1],1,sz_1403[3])
;Calculate velocity based on wavelength
     velocity_1394=3e5*(lambda_1394-lambda0_1394)/lambda0_1394 ;km/s
     velocity_1403=3e5*(lambda_1403-lambda0_1403)/lambda0_1403 ;km/s
;Locate where velocity is within chosen bounds
     indices_1394=where((velocity_1394[*,0,0] le 50) AND (velocity_1394[*,0,0] ge -50))
     indices_1403=where((velocity_1403[*,0,0] le 50) AND (velocity_1403[*,0,0] ge -50))
;Apply bounds of shift and event to velocity array
     maxv_1394=max(where(velocity_1394[*,0,0] ge 50))
     minv_1394=min(where(velocity_1394[*,0,0] le -50))

     maxv_1403=max(where(velocity_1403[*,0,0] ge 50))
     minv_1403=min(where(velocity_1403[*,0,0] le -50))

     velocity_1394=velocity_1394[minv_1394:maxv_1394,0,x0:x1]
     velocity_1403=velocity_1403[minv_1403:maxv_1403,0,x0:x1]
;Remove large arrays we no longer need
     undefine, lambda0_1394
     undefine, lambda0_1403
     undefine, lambda_1394
     undefine, lambda_1403
;Define data arrays for event     
     data_1394=si_struct.si_1394_data[minv_1394:maxv_1394,y0:y1,x0:x1]
     data_1403=si_struct.si_1403_data[minv_1403:maxv_1403,y0:y1,x0:x1]
;Define slit position axis
     slit_pos_axis=findgen(sz_1394[2])/max(findgen(sz_1394[2]))*si_struct.si_1394_index[0].fovy
     slit_pos_axis-=mean(slit_pos_axis)
     slit_pos_axis+=si_struct.si_1394_index[0].ycen
;Define time axis
     time_axis=si_struct.si_1394_index.time/3600+12.5
;Calculate chi     
     chisq=ee_calchi(data_1394,data_1403,velocity_1394,velocity_1403)
     mx=array_indices(chisq, where(chisq eq max(chisq)))
     ;p=plot(velocity_1394[*,0,mx[1]], data_1394[*,mx[0],mx[1]],'-r')
    ; p=plot(velocity_1403[*,0,mx[1]], data_1403[*,mx[0],mx[1]], '-b',/overplot,xrange=[-300,300])
     STOP
;Determine new size of data arrays
     sz_1394=size(data_1394,/structure)
     sz_1403=size(data_1403,/structure)
;Gaussian fit on the spectral lines     
     g_1394=data_1394*0
     g_1403=data_1403*0
     
     fit_1394=fltarr(9,sz_1394.dimensions[1],sz_1394.dimensions[2])
     fit_1403=fltarr(9,sz_1403.dimensions[1],sz_1403.dimensions[2])

     fit_chi2_1394=fltarr(sz_1394.dimensions[1],sz_1403.dimensions[2])
     fit_chisq_1403=fltarr(sz_1403.dimensions[1],sz_1403.dimensions[2])

     if file_search(directory+"gaussfit_"+strcompress(string(event),/remove_all)+"/") eq "" then file_mkdir, directory+"gaussfit_"+strcompress(string(event),/remove_all)+"/"

     for i=0,y1-y0-1 do begin
        for j=0,x1-x0-0 do begin
           ;; if total(data_1394[*,i,j]) eq 0 then begin
           ;;    g_1394[0,i,j]=fltarr(sz_1493.dimensions[0])
           ;;    fit_1394[0,i,j]=fltarr(9)
           ;; endif else begin
           ;;    if max(data_1394[*,i,j]) lt 20 then begin
           ;;       g_1394[0,i,j]=fltarr(sz_1394.dimensions[0])
           ;;       fit_1394[0,i,j]=fltarr(9)
           ;;    endif else begin
           ;;       g_1394[0,i,j]=gauss_fit(velocity_1394[*,0,j],data_1394[*,i,j],a1,/no_back,chi2=chi2)
;ds           ;;       fit[0,i,j]=a1
           ;;       fit_chisq_1394=chi2
           ;;       if abs(a1[4]) ge 200 then begin
           ;;          g[0,i,j]=fltarr(sz_1394.dimensions[0])
           ;;          fit[0,i,j]=fltarr(9)
           ;;       endif
           ;;       if abs(a1[4]) lt 200 gt 100 then begin
           ;;          p=plot(velocity_1394[*,*,j],data_1394[*,i,j],'*')
           ;;          p=plot(velocity_1394[*,*,j],g_1394[*,i,j],/overplot)
           ;;       endif
           ;;    endelse
           ;; endelse
           if total(data_1403[*,i,j]) eq 0 then begin
              g_1403[0,i,j]=fltarr(sz_1403.dimensions[0])
              fit_1403[0,i,j]=fltarr(9)
           endif else begin
              if max(data_1403[*,i,j]) lt 20 then begin
                 g_1403[0,i,j]=fltarr(sz_1403.dimensions[0])
                 fit_1403[0,i,j]=fltarr(9)
              endif else begin
                 g_1403[0,i,j]=gauss_fit(velocity_1403[*,0,j],data_1403[*,i,j],a2,/no_back,chi2=chi2)
                 fit_1403[0,i,j]=a2
                 fit_chisq_1403=chi2
                 if abs(a2[4]) ge 200 then begin
                    g_1403[0,i,j]=fltarr(sz_1403.dimensions[0])
                    fit_1403[0,i,j]=fltarr(9)
                 endif
                 if abs(a2[4]) lt 200 gt 100 then begin
                    p=plot(velocity_1403[*,*,j],data_1403[*,i,j],'*',/buffer)
                    p=plot(velocity_1403[*,*,j],g_1403[*,i,j],/overplot)
                    p.save, directory+"gaussfit/gaussian_"+strcompress(string(i),/remove_all)+strcompress(string(j),/remove_all)+".png"
                 endif
              endelse
           endelse
        endfor
     endfor

     for i = 0,y1-y0-1 do begin
     for j = 0,x1-x0-1 do begin
        ;; print,'[i,j]',i,',',j
        if total(data_1394[*,i,j]) eq 0 then begin
           g_1394[0,i,j] = fltarr(sz_1394.dimensions[0])
           fit_1394[0,i,j] = fltarr(9)
        endif else begin
           if max(data_1394[*,i,j]) lt 20 then begin
              g_1394[0,i,j] = fltarr(sz_1394.dimensions[0])
              fit_1394[0,i,j] = fltarr(9)
           endif else begin
              a=0
              g_1394[0,i,j] = gauss_fit(velocity_1394[*,0,j],data_1394[*,i,j],a,/no_back,chi2 = chi2,double=0)
              fit_1394[0,i,j] = a
              fit_chi2_1394[i,j] = chi2
              
              if chi2 gt 1e5 then begin
                 a=0
                 g_1394[0,i,j] = gauss_fit(velocity_1394[*,0,j],data_1394[*,i,j],a,/no_back,chi2 = chi2_double,double=1)
                 fit_1394[0,i,j] = fltarr(9)
                 fit_1394[0,i,j] = a

                 if abs(a[7]) gt 60 then begin
                    a=0
                    g_1394[0,i,j] = gauss_fit(velocity_1394[*,0,j],data_1394[*,i,j],a,/no_back,chi2 = chi2,double=0)
                    fit_1394[0,i,j] = fltarr(9)
                    fit_1394[0,i,j] = a
                    fit_chi2_1394[i,j] = chi2
                    
                 endif else fit_chi2_1394[i,j] = chi2_double
                 
                 if chi2 lt chi2_double then begin
                    a=0
                    g_1394[0,i,j] = gauss_fit(velocity_1394[*,0,j],data_1394[*,i,j],a,/no_back,chi2 = chi2,double=0)
                    fit_1394[0,i,j] = fltarr(9)
                    fit_1394[0,i,j] = a
                    fit_chi2_1394[i,j] = chi2
                    
                 endif else fit_chi2_1394[i,j] = chi2_double
                 
                   
              endif
              
              if abs(a[4]) ge 200 then begin
                 g_1394[0,i,j] = fltarr(sz_1394.dimensions[0])
                 fit_1394[0,i,j] = fltarr(9)
              endif
              if abs(a[4]) lt 200 gt 100 then begin
       
                 ;plot,ee16_vel[*,*,j],ee16[*,i,j],psym=2
                 ;oplot,ee16_vel[*,*,j],g[*,i,j]
                 ;STOP
              endif
              a=0
           endelse
        endelse
     end
  end
     
  doppler_shifts = total_1d(fit_1403[4,*,*],1)
  doppler_shifts = transpose(doppler_shifts)
  doppler_shifts[where(doppler_shifts eq 0)] = mean(total(doppler_shifts[*,0:10],2)/11)
  doppler_shifts -= mean(total(doppler_shifts[*,0:10],2)/11)
  velo_map4 = image(doppler_shifts[0:-1,*],indgen(n_elements(doppler_shifts[0:-1,0]))+150,indgen(y1-y0+1),title=strmid(directory,11,10)+" event "+strcompress(string(event),/remove_all),layout=[2,1,1],xtitle='Time (exposure count)',ytitle='Slit Position (pixels)',margin=0.1,axis_style=1,dimensions=[1024,512])
  velo_map4.rgb_table = colortable(70,/reverse)
  velo_map4.max_value = 50
  velo_map4.min_value = -50
  ;cb4 = colorbar(target = velo_map3,title='Doppler Shift (km/s)',orientation=1)

;Plot chi squared as intensity map     
STOP
     chisq_map=image(transpose(chisq[*,*]),indgen(n_elements(chisq[0,*])),indgen(n_elements(chisq[*,0])), title=strmid(directory,11,10)+" chi2 for event "+strcompress(string(event),/remove_all),layout=[2,1,1],xtitle="Time (exposure count)", ytitle="Slit Position (pixels)", margin=0.1, axis_style=1, dimensions=[1024,512])

     chisq_map.rgb_table=colortable(53,/reverse)
     ;cb=colorbar(target=chisq_map,title="Chi Squared Value",orientation=1)
     STOP
  ;; Time = 279
  ;; peak_time = si_1403_index[time].date_obs
  ;; xr = [-100,100]
  ;; n=floor(y1-y0)/4.
  ;; ;oplot fits
  ;; color = 'red'


     for nplots=0,8 do begin
        ypos=(nplots mod 3)*(-6)+40
        xpos=(nplots/3)*6+13

        pn=plot(velocity_1394[*,0,xpos], data_1394[*,ypos,xpos],'-r')
        pn=plot(velocity_1403[*,0,xpos], data_1403[*,ypos,xpos], '-b',/overplot,xrange=[-100,100], yrange=[min(data_1403[*,ypos,xpos]),max(data_1394[*,ypos,xpos])])
        pn.title="Spectrum 1394A (red) and 1403A (blue) on 2015/05/09 at "+si_struct.si_1403_index[xpos].date_obs
        pn.xtitle="Velocity (km/s)"
        pn.ytitle="Intensity"

     endfor
  endif else begin
     interesting=interesting[index,*]

     x0=mouseread.x0[where(interesting eq 1)]
     x1=mouseread.x1[where(interesting eq 1)]
     y0=mouseread.y0[where(interesting eq 1)]
     y1=mouseread.y1[where(interesting eq 1)]

     sz_1394=size(si_struct.si_1394_data)
     sz_1403=size(si_struct.si_1403_data)
     
     lambda0_1394=si_struct.si_1394_index[0].wavelnth
     lambda0_1394=reform(lambda0_1394,1,1,sz_1394[3])
     lambda0_1394=rebin(lambda0_1394,sz_1394[1],1,sz_1394[3])
     
     lambda0_1403=si_struct.si_1403_index[0].wavelnth
     lambda0_1403=reform(lambda0_1403,1,1,sz_1403[3])
     lambda0_1403=rebin(lambda0_1403,sz_1403[1],1,sz_1403[3])

     lambda_1394=si_struct.si_1394_index[0].wavemin+si_struct.si_1394_index[0].cdelt1*findgen(si_struct.si_1394_index[0].naxis1)
     lambda_1394=rebin(lambda_1394,sz_1394[1],1,sz_1394[3])
     
     lambda_1403=si_struct.si_1403_index[0].wavemin+si_struct.si_1403_index[0].cdelt1*findgen(si_struct.si_1403_index[0].naxis1)
     lambda_1403=rebin(lambda_1403,sz_1403[1],1,sz_1403[3])
     
     velocity_1394=3e5*(lambda_1394-lambda0_1394)/lambda0_1394    ;km/s
     velocity_1403=3e5*(lambda_1403-lambda0_1403)/lambda0_1403    ;km/s
     
     indices_1394=where((velocity_1394 le 50) AND (velocity_1394 ge -50))
     indices_1403=where((velocity_1403 le 50) AND (velocity_1403 ge -50))
     
     velocity_1394=velocity_1394(indices_1394)
     velocity_1403=velocity_1403(indices_1403)
     
     undefine, lambda0_1394
     undefine, lambda0_1403
     undefine, lambda_1394
     undefine, lambda_1403
     
     for n=0,n_elements(x0)-1 do begin
        data_1394=si_struct.si_1394_data[indices_1394,y0[n]:y1[n],x0[n]:x1[n]]
        data_1493=si_struct.si_1403_data[indices_1403,y0[n]:y1[n],x0[n]:x1[n]]
        
        chisq=ee_calchi(data_1394,data_1403,velocity_1394,velocity_1403)

        
     endfor
  endelse
     
end
