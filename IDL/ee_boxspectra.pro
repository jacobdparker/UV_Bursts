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
           int=interpol(data_1403[*,slit,t],vel_1403, vel_1394)
           chisq[slit,t]=total((data_1394[*,slit,t]-2*int)^2)
        endfor
     endif else begin
        for t=0,n_time-1 do begin
           int=interpol(data_1394[*,slit,t],vel_1394,vel_1403)
           chisq[slit,t]=total((int-2*data_1403[*,slit,t])^2)
        endfor
     endelse
  endfor

  return, chisq
end

;FUNCTION: ee_findint
;PURPOSE: determine if an event has values where chi squared is larger
;than the mean times a chosen scalar alpha
;RETURNS: 0 if not, 1 if yes
;CALLING SEQUENCE: ee_findint(chisq, alpha)
;AUTHOR(S): A.E. Bartz, 7/19/17
function ee_findint, chisq, alpha

  indices=where(chisq gt mean(chisq)*alpha)
  if n_elements(indices) eq 1 then begin
     if indices eq -1 then int=0 else int=1
  endif else int=1
  
  return, int
end

;PROCEDURE: ee_maxspectra
;PURPOSE: find the maximum chi squared value for an interesting event
;and plot the spectrum at that time and position
;SAVES: a plot of the spectrum at maximum chi squared
;CALLING SEQUENCE: ee_maxspectra, timefile, t0, chi_struct, i
pro ee_maxspectra, timefile, t0, chi_struct, i

  maxchi_slit=0
  maxchi_t=0

  for slit=0,n_elements(chi_struct.chisq[*,0])-1 do begin
     for t=0,n_elements(chi_struct.chisq[0,*])-1 do begin
        if chi_struct.chisq[slit,t] gt chi_struct.chisq[maxchi_slit,maxchi_t] then begin
           maxchi_slit=slit
           maxchi_t=t
        endif
     endfor
  endfor

  restore, timefile
  actual_time=dateobs[t0+maxchi_t]

  p1=plot(chi_struct.velocity_1394,chi_struct.current_1394_data[*,maxchi_slit,maxchi_t],'-r',/widgets,/buffer)
  p1=plot(chi_struct.velocity_1403,chi_struct.current_1403_data[*,maxchi_slit,maxchi_t],'-b',/overplot,/buffer)
  p1.title="Spectrum of 1394A/1403A at maximum chi squared "+actual_time
  p1.xtitle="Velocity (km/s)"
  p1.ytitle="Intensity"
  p1.save, strmid(timefile,0,22)+"maxchi_20"+strmid(timefile,11,4)+strmid(timefile,16,2)+strmid(timefile,19,2)+"_"+strmid(actual_time,11,2)+strmid(actual_time,14,2)+strmid(actual_time,17,2)+"_"+strcompress(string(i),/remove_all)+".png"
  
end

;FUNCTION: ee_srestore
;PURPOSE: load & despike data, store as a structure, and return to MAIN
;RETURNS:
;CALLING SEQUENCE: ee_srestore(eepath,boxfile, eefile, gmapfile, Niter)
;AUTHOR(S): A.E. Bartz, 7/19/17
function ee_srestore, eepath,  boxfile, eefile, gmapfile, Niter
  common widget_environment, img, didx, tidx, mouseread
  common ee_environment, rasterfile, rasterdir, sjifile, siIV_EE_map, goodmap, goodmap1403
;Load data
  ee_gunzip, eepath, rasterdir

  message, 'Reading SJI data...',/information
  sjifile=file_search(rasterdir, "*_1400_t000.fits")
  read_iris_l2, sjifile, sjiindex

  message, 'Reading raster data...',/information
  rasterfile=file_search(rasterdir, "*_raster_t000*")
  read_iris_l2, rasterfile, si_1394_index, si_1394_data, WAVE='Si IV'
  read_iris_l2, rasterfile, si_1403_index, si_1403_data, WAVE='Si IV 1403'

  
;Despike the 1394 line, based on existence of an ee file in the rasterdir
  message, 'Despiking Si 1394..',/information
  if eefile eq "" then begin
     si_1394_data=despik(si_1394_data, sigmas=4.0, Niter=Niter,$
                         min_std=4.0,  goodmap=goodmap)
  endif else begin
     restore, eefile
     si_1394_data=despik(si_1394_data, sigmas=4.0, Niter=Niter,$
                            min_std=4.0,  goodmap=goodmap, /restore)
  endelse
  message, 'Removing instrumental background...',/information
  dark_model=fuv_bg_model(si_1394_data, percentile=35, /replace)

;Despike the 1403 line, based on existence of goodmap in the rasterdir  
  message, 'Despiking Si 1403...',/information
  if gmapfile eq "" then begin
     si_1403_data=despik(si_1403_data,sigmas=4.0,Niter=Niter,$
                         min_std=4.0,goodmap=goodmap_1403)
  endif else begin
     restore, gmapfile
     si_1403_data=despik(si_1403_data, sigmas=4.0, Niter=Niter,$
                         min_std=4.0,  goodmap=goodmap_1403, /restore)
  endelse
  message, 'Removing instrumental background...',/information
  dark_model=fuv_bg_model(si_1403_data,percentile=35,/replace)

  
;Create EE SiIV_EE_map
  lambda = si_1394_index[0].wavemin + si_1394_index[0].cdelt1*findgen(si_1394_index[0].naxis1) ;wavelength axis, Angstroms
  lambda0 = Si_1394_index.wavelnth ;central wavelength for Si IV.
  c = 3e5                       ;speed of light, km/s
  velocity = c * (lambda - lambda0)/lambda0 ;velocity axis, km/s
  explosive_threshold = 60.0    ;km/s. SiIV has T=10^4.8, c_s = 40 km/s.
  explosive_velocities = abs(velocity) gt explosive_threshold ;mask in wavelength space
  SiIV_Nt = (size(si_1394_data))[3]
  SiIV_Ny = (size(si_1394_data))[2]
  SiIV_EE_map = fltarr(SiIV_Nt, SiIV_Ny)
  for i=0, SiIV_Nt-1 do begin   ;cycle through FUV SG exposures.
                                ;Evaluate a measure of explosive event activity for this timestep
     SiIV_EE_map[i,*] = total( (explosive_velocities # replicate(1.0,SiIV_Ny)) * Si_1394_data[*,*,i], 1)
  endfor

  
;Now that we've generated all of the data, save and return it  
  save, rasterfile, rasterdir, sjifile, SiIV_EE_map, file=rasterdir+"ee_"+strmid(boxfile,28,5)+"_20.sav"
  save, goodmap_1403, file=rasterdir+"goodmap_1403_"+strmid(boxfile,28,5)+"_20.sav"
  
  si_struct={si_1394_index:si_1394_index,si_1394_data:si_1394_data,si_1403_index:si_1403_index,si_1403_data:si_1403_data,rasterdir:rasterdir}

  return, si_struct
end

;PROCEDURE: ee_boxspectra
;PURPOSE: act as a kernel to load and constrain data and determine max
;chi
;CALLING SEQUENCE: ee_boxspectra, alpha, Niter
;AUTHOR(S): A.E. Bartz, 7/19/17
pro ee_boxspectra, alpha, Niter

  
;Find the files needed and restore fits filepaths
  boxfiles=file_search('../EE_Data','boxes*.sav')
  boxfiles=boxfiles[1:-1]
  timefiles=file_search('../EE_Data','dateobs*.sav')
  restore, "ee_obs_paths.sav"
  nfiles=n_elements(boxfiles)
  
  
;If we've already saved some interesting events, load them,
;otherwise start the "interesting events" array  
  if file_search("ee_interesting.sav") ne "" then restore, "ee_interesting.sav" else interesting=fltarr(32,65)
;Alpha is our scalar to determine the interesting events

;Set the wrapper state - which file to start on?  
  if file_search('ee_wrapper_state.sav') eq "" then wrapper_state=0 else $
     restore, "ee_wrapper_state.sav"

  if wrapper_state ge nfiles then begin
     STOP, "All files already finished"
  endif
  
;Start loop 
  while wrapper_state lt nfiles do begin
;If we don't have 1403 data for the index, skip it and set interesting=-1     
     if ((wrapper_state eq 2) OR (wrapper_state eq 6) OR (wrapper_state eq 20) OR (wrapper_state eq 26)) then begin
        interesting[wrapper_state,*]=-1
        wrapper_state++
        save, wrapper_state, file="ee_wrapper_state.sav"
        continue
     endif
     
     print, "Locating files..."
     current_dir=strmid(boxfiles[wrapper_state],0,22) 
     despike=0
     
     if file_search(current_dir, "si_data_"+strmid(boxfiles[wrapper_state],28,5)+"_20.sav") ne "" then restore, file_search(current_dir, "si_data_"+strmid(boxfiles[wrapper_state],28,5)+"_20.sav") else despike=1
        
     if despike eq 1 then begin
;If we have to despike, see if there is already a file we can despike
;with and pass the search results into the restore function        
        eefile=file_search(current_dir, "ee_"+strmid(boxfiles[wrapper_state],28,5)+"_20.sav")
        if eefile eq "" then eefile=file_search(current_dir, "ee.sav")
           
        gmapfile=file_search(current_dir,"goodmap_1403_"+strmid(boxfiles[wrapper_state],28,5)+"_20.sav")         
        if gmapfile eq "" then gmapfile=file_search(current_dir, "goodmap_1403.sav")
        
;Send eefile, gmap file, and fits filepath to eerestore to despike and
;load data along with boxfile so we can name them appropriately
        print, "Sending data to despike..."
        si_struct=ee_srestore(ee_obs_path[wrapper_state], boxfiles[wrapper_state], eefile, gmapfile, Niter)
        save, si_struct, file=current_dir+"si_data_"+strmid(boxfiles[wrapper_state],28,5)+"_15.sav"
     endif

;Make velocity axes
     print, "Beginning velocity analysis..."
     lambda0_1394=si_struct.si_1394_index[0].wavelnth
     lambda0_1403=si_struct.si_1403_index[0].wavelnth

     lambda_1394=si_struct.si_1394_index[0].wavemin+si_struct.si_1394_index[0].cdelt1*findgen(si_struct.si_1394_index[0].naxis1)
     lambda_1403=si_struct.si_1403_index[0].wavemin+si_struct.si_1403_index[0].cdelt1*findgen(si_struct.si_1403_index[0].naxis1)

     velocity_1394=3e5*(lambda_1394-lambda0_1394)/lambda0_1394 ;km/s
     velocity_1403=3e5*(lambda_1403-lambda0_1403)/lambda0_1403 ;km/s

;Find where to crop
     indices_1394=where((velocity_1394 le 50) AND (velocity_1394 ge -50))
     indices_1403=where((velocity_1403 le 50) AND (velocity_1403 ge -50))

     velocity_1394=velocity_1394(indices_1394)
     velocity_1403=velocity_1403(indices_1403)

     si_1394_data=si_struct.si_1394_data(indices_1394,*,*)
     si_1403_data=si_struct.si_1403_data(indices_1403,*,*)

;Free memory
     undefine, lambda0_1394
     undefine, lambda0_1403
     undefine, lambda_1394
     undefine, lambda_1403

     
;Begin event loop
     restore, boxfiles[wrapper_state]
     count=mouseread.count
     for i=0,count do begin

        sz_1394=size(si_1394_data)
        sz_1403=size(si_1403_data)
        
        if (mouseread.x1[i] ge sz_1394[3]) then mouseread.x1[i]=sz_1394[3]-1
        if (mouseread.y1[i] ge sz_1394[3]) then mouseread.y1[i]=sz_1394[3]-1
        if ((mouseread.x0[i] eq mouseread.x1[i]) AND (mouseread.y0[i] eq mouseread.y1[i])) then continue
        if (mouseread.x0[i] ge mouseread.x1[i]) then mouseread.x0[i]=mouseread.x1[i]-1
        if (mouseread.y0[i] ge mouseread.y1[i]) then mouseread.y0[i]=mouseread.y1[i]-1
        if mouseread.x0[i] lt 0 then mouseread.x0[i]=0
        if mouseread.y0[i] lt 0 then mouseread.y0[i]=0
        
        print, "Iterating event number"+string([i])+" for observation"+string([wrapper_state])

                                ;Crop data arrays to time, slit
                                ;height, velocity at appropriate value
        current_1394_data=si_1394_data[*,$
                                       mouseread.y0[i]:mouseread.y1[i],$
                                       mouseread.x0[i]:mouseread.x1[i]]
        current_1403_data=si_1403_data[*,$
                                       mouseread.y0[i]:mouseread.y1[i],$
                                       mouseread.x0[i]:mouseread.x1[i]]


;Chi squared calculation at all observation times
        chisq=ee_calchi(current_1394_data,current_1403_data,velocity_1394,velocity_1403)

;Determine which events are "interesting" based on alpha
        interesting[wrapper_state,i]=ee_findint(chisq, alpha)
        
;If the event is interesting, plot the spectrum at maximum chi
        if interesting[wrapper_state,i] eq 1 then begin
           chi_struct={chisq:chisq,current_1394_data:current_1394_data,current_1403_data:current_1403_data,velocity_1394:velocity_1394,velocity_1403:velocity_1403}
           ee_maxspectra, timefiles[wrapper_state], mouseread.x0[i], chi_struct, i
        endif
     endfor
     
     
;Remove fits files & clear memory so we can save plots if needed
     fts=file_search('../EE_Data','*.fits')
     if fts[0] ne "" then ee_dataclear, ee_obs_path[wrapper_state]

;Save wrapper_state, interesting events and iterate
     wrapper_state++
     save, wrapper_state, file="ee_wrapper_state.sav"
     save, interesting, file="ee_interesting.sav"
     print, "Continuing on to iteration number"+string([wrapper_state])
  endwhile 
  
end
