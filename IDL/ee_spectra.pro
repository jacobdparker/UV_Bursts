;SCRIPT: ee_spectra
;PURPOSE: load 1394 & 1403 A Silicon IV line data and perform optical
;depth analyses
;CALLING SEQUENCE: ee_spectra
;AUTHOR(S): A.E. Bartz, 6/27/17

pro ee_spectra
  common widget_environment, img, didx, tidx, mouseread
  common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map, goodmap, goodmap_1403
  common data, si_1394_index,si_1394_data,sjiindex,sjidata,si_1403_index, si_1403_data,fe_index,fe_data
  
;Find the ee files needed and restore fits filepaths
  eefiles=file_search('../EE_Data','ee_*_15.sav')
  restore, "ee_obs_paths.sav"
  nfiles=n_elements(eefiles)
  obstimes=file_search('../EE_Data','dateobs*.sav')

;Set the wrapper state - which file to start on?  
  if file_search('ee_wrapper_state.sav') eq "" then wrapper_state=0 else $
     restore, "ee_wrapper_state.sav"

  if wrapper_state ge nfiles then begin
     STOP, "All files already finished"
  endif
  
;Start loop 
  while wrapper_state lt nfiles do begin

;If we've already saved the second goodmap file with the name
;extended then save our index and skip to next loop
     print, "Restoring ee files..."
     restore, eefiles[wrapper_state]
     restore, obstimes[wrapper_state]
     if file_search(rasterdir,"goodmap1403_"+strmid(eefiles[wrapper_state],25,5)+"_15.sav") ne "" then begin
        char=''
        read, char, prompt="There seems to already be a goodmap1403 file in this directory. Press N to continue to next iteration or any other key to continue: "
        if ((char eq 'n') or (char eq 'N')) then begin
           wrapper_state++
           save, wrapper_state, file="ee_wrapper_state.sav"
           continue
        endif else begin
           restore, rasterdir+"goodmap1403_"+strmid(eefiles[wrapper_state],25,5)+"_15.sav"
           restor=1
        endelse
     endif

 
     
;If we already have a goodmap for 1403 data, then restore and send the
;message to despike so it doesn't despike the whole thing again     
     file=file_search(rasterdir,"goodmap1403.sav")
     if file ne "" then begin
        restore, file
        restor=1
     endif

     if restor ne 1 then restor=0
     
;Send ee file and fits filepath to eerestore to despike and load data
     print, "Sending data to despike"
     eerestore, ee_obs_path[wrapper_state], restor

;Make wavelength axes
     print, "Beginning velocity analysis"
     lambda_1394=si_1394_index[0].wavemin+si_1394_index[0].cdelt1*findgen(si_1394_index[0].naxis1)
     lambda_1403=si_1403_index[0].wavemin+si_1403_index[0].cdelt1*findgen(si_1403_index[0].naxis1)

;Find central wavelengths for Si IV lines
     lambda0_1394=si_1394_index[0].wavelnth
     lambda0_1403=si_1403_index[0].wavelnth

;Make velocity axes and find cutoff indices (cutoff +/-100 km/s)    
     velocity_1394=3e5*(lambda_1394-lambda0_1394)/lambda0_1394 ;km/s
     velocity_1403=3e5*(lambda_1403-lambda0_1403)/lambda0_1403 ;km/s
     
     indices_1394=where((velocity_1394 le 150) AND (velocity_1394 ge -150))
     indices_1403=where((velocity_1403 le 150) AND (velocity_1403 ge -150))

;Collapse whole slit on itself     
     sum_1394=total_1d(si_1394_data,2) 
     sum_1403=total_1d(si_1403_data,2)     

;Apply cutoffs to collapsed data and velocity axes     
     velocity_1394=velocity_1394(indices_1394)
     sum_1394=sum_1394(indices_1394,*)
     
     velocity_1403=velocity_1403(indices_1403)
     sum_1403=sum_1403(indices_1403,*)


     STOP
;Free memory for arrays we won't use again
     undefine, indices_1394
     undefine, indices_1403
     undefine, lambda0_1394
     undefine, lambda0_1403
     undefine, lambda_1403
     undefine, lambda_1394

     ;This only plots time=0, so it is unhelpful
;; ;Plot 1394 and 1403 lines on the same set of axes
;;      p1=plot(velocity_1394,sum_1394,'r',/widgets)
;;      p1=plot(velocity_1403,sum_1403,'b',/overplot)
;;      p1.title="Si IV 1394A (red) and 1403A (blue)"
;;      p1.xtitle="Velocity (km/s)"
;;      p1.ytitle="Intensity"
     
;Chi squared calculation at all observation times
     sz_1394=size(sum_1394)
     sz_1403=size(sum_1403)
     chisq=fltarr(sz_1394[2])

     print, "Calculating chi squared"
     
                                ;Just kidding, I had to make for loops :(
     if sz_1394[1] eq sz_1403[1] then begin
        for i=0,sz_1394[2]-1 do begin
           chisq[i]=total((sum_1394[*,i]-2*sum_1403[*,i])^2)
        endfor
     endif else begin
        larger=(sz_1394[1] lt sz_1403[1])
        if larger eq 1 then begin ;If sum_1403 is larger, then interpolate to fit 1394 grid
           for i=0,sz_1394[2]-1 do begin
              int=interpol(sum_1403[*,i],velocity_1403,velocity_1394)
              chisq[i]=total((sum_1394[*,i]-2*int)^2)
           endfor
        endif else begin        ;Otherwise sum_1394 is larger and we interpolate to fit 1403 grid
           for i=0,sz_1394[2]-1 do begin
              int=interpol(sum_1394[*,i],velocity_1394,velocity_1403)
              chisq[i]=total((int-2*sum_1403[*,i])^2)
           endfor
        endelse
     endelse
     
;Free memory we no longer need     
     undefine, sz_1403
     undefine, sz_1394
     undefine, sum_1394
     undefine, sum_1403
     
;Convert observation times into plottable values (hours from start of observation)
     dateobs=greg2jul(strmid(dateobs,5,2),strmid(dateobs,8,2),strmid(dateobs,0,4),$
                    strmid(dateobs,11,2),strmid(dateobs,14,2),strmid(dateobs,17,2))
     dateobs=(dateobs-dateobs[0])*24
     
;Plot chi squared as a function of time
     p2=plot(dateobs,chisq,/widgets,'r')
     p2.title="Chi squared as a function of time on "+strmid(eefiles[wrapper_state],11,10)
     p2.xtitle="Hours from beginning of exposure"
     p2.ytitle="Chi squared"

;; We determined that the following section of code is unnecessary
;; with chi-squared analysis
;; STOP
;; ;Calculate indices where we will interpolate 1394 data to fit 1403 velocities
;;      fit_1403=linfit(velocity_1403, indgen(n_elements(velocity_1403)))
;;      indices_1394=fit_1403[0]+fit_1403[1]*velocity_1394
;; STOP
;; ;Interpolate 1394 data to fit 1403 velocities
;;      int_1394=interpolate(sum_1394,indices_1394,/grid,missing=0)
;;      sz_1394=size(int_1394)
;; STOP   
;; ;Calculate line ratio
;;      diff=(n_elements(velocity_1403)-n_elements(velocity_1394))/2
;;      if diff eq round(diff) then begin
;;         if diff eq 0 then lineratio=int_1394/sum_1403(*,0:sz_1394[2])
;;         if diff gt 0 then lineratio=int_1394/sum_1403((diff-1):n_elements(sum_1403)-diff)
;;      endif
STOP

;Remove fits files & clear memory so we can save plots if needed
     ee_dataclear, ee_obs_path[wrapper_state]

     undefine, chisq
     undefine, dateobs
     
     undefine, si_1394_data
     undefine, si_1394_index
     undefine, velocity_1394

     undefine, si_1403_data
     undefine, si_1403_index
     undefine, velocity_1403
     
;Determine whether to continue
     char=''
     read, char, prompt="You just completed iteration number"+string([wrapper_state])+". Continue operations? Press N to quit or any other key to continue: "
     if (char eq 'n') OR (char eq 'N') then break

;If continue then save final version of goodmap_1403
     STOP, "Stopping so you can save plots. Press .c to continue"
     file_move, rasterdir+"goodmap1403.sav", rasterdir+"goodmap1403_"+strmid(eefiles[wrapper_state],25,5)+"_15.sav"
     wrapper_state++
     save, wrapper_state, file="ee_wrapper_state.pro"
     print, "Continuing on to iteration number"+string([wrapper_state])
  endwhile
     
end
