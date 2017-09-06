pro ee_explore_event,event
  
 
  common widget_environment, img, didx, tidx, mouseread
  common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map
  common data, rasterindex,rasterdata,sjiindex,sjidata,si_1403_index, si_1403_data,fe_index,fe_data

;Gather the ID of each widget by name  
  time_id = widget_info(event.top,find_by_uname='time')
  ee_event_id = widget_info(event.top,find_by_uname='ee_event')
  pos_id = widget_info(event.top,find_by_uname='position')
  p1_id = widget_info(event.top,find_by_uname='P1')
    p2_id = widget_info(event.top,find_by_uname='P2')

;Gather the state of each slider
    widget_control, time_id,get_value=time
    widget_control,pos_id,get_value=slit_position
    widget_control,ee_event_id,get_value = ee_event   
 

  ;Define event indicies(sp?)
    
    x0 = mouseread.x0[ee_event]
    x1 = mouseread.x1[ee_event]
    y0 = mouseread.y0[ee_event]
    y1 = mouseread.y1[ee_event]

    
    if event.id eq ee_event_id then begin
       widget_control, time_id,set_slider_min = x0, set_slider_max= x1, set_value = x0
       widget_control, pos_id,set_slider_min = y0, set_slider_max= y1, set_value = y0
    endif

    

;Build calibrated lambda and velocity vectors

    raster_size= size(rasterdata)
    wavemin = rasterindex[0].wavemin
    wavemax = rasterindex[0].wavemax
    wavesz = raster_size[1]
    lambda = wavemin + rasterindex[0].cdelt1*findgen(rasterindex[0].naxis1) ;wavelength axis, Angstroms
    lambda0 = rasterindex.wavelnth  ;central wavelength for Si IV.
    c = 3e5                         ;speed of light, km/s
    velocity = c * (lambda - lambda0)/lambda0 ;velocity axis, km/s

    raster_size= size(si_1403_data)
    wavemin = si_1403_index[0].wavemin
    wavemax = si_1403_index[0].wavemax
    wavesz = raster_size[1]
    lambda_1403 = wavemin + si_1403_index[0].cdelt1*findgen(si_1403_index[0].naxis1) ;wavelength axis, Angstroms
    lambda0 = si_1403_index.wavelnth  ;central wavelength for Si IV.
    velocity_1403 = c * (lambda_1403 - lambda0)/lambda0 ;velocity axis, km/s
    
    raster_size= size(fe_data)
    wavemin = fe_index[0].wavemin
    wavemax = fe_index[0].wavemax
    wavesz = raster_size[1]
    lambda_fe = wavemin + fe_index[0].cdelt1*findgen(fe_index[0].naxis1) ;wavelength axis, Angstroms
    lambda0 = fe_index.wavelnth  ;central wavelength for Si IV.
    velocity_fe = c * (lambda_fe - lambda0)/lambda0 ;velocity axis, km/s
    
        
    widget_control,p1_id,get_value=p1ID  
    p1ID.erase
    p1ID.select

    ;velocity -=12
    line_profile = rasterdata[*,slit_position,time]
    int_scale = max(rasterdata[*,slit_position,x0:x1])
    p=plot(velocity,line_profile,yr=[0,max(line_profile)],xr=[-100,100],title = rasterindex[time].date_obs,/current)

    ;velocity_1403 -=12
    line_profile = si_1403_data[*,slit_position,time]
    int_scale = max(si_1403_data[*,slit_position,x0:x1])
    p=plot(velocity_1403,2*line_profile,/overplot,color='red')

    widget_control,p2_ID,get_value=p2ID
    p2ID.select
    p2ID.erase

    line_profile = fe_data[*,slit_position,time]
    int_scale = max(fe_data[*,slit_position,x0:x1])
    p=plot(lambda_fe,line_profile,/current,yr=[0,max(line_profile)])
 STOP
end



    
    

pro ee_explore

    common widget_environment, img, didx, tidx, mouseread
    common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map
    common data, rasterindex,rasterdata,sjiindex,sjidata,si_1403_index, si_1403_data,fe_index,fe_data
    
    ;Define event indicies(sp?)

    ee_count = mouseread.count
    x0 = mouseread.x0[0:ee_count-1]
    x1 = mouseread.x1[0:ee_count-1]
    y0 = mouseread.y0[0:ee_count-1]
    y1 = mouseread.y1[0:ee_count-1]
    
   
    ee_event=0
    base = widget_base(/column)
    slider = widget_base(base,/row)
    if ee_count eq 1 then begin
       event_slider = widget_slider(slider,title='Event Number',uname='ee_event')
    endif else begin
       event_slider = widget_slider(slider,title='Event Number',maximum = ee_count-1,uname='ee_event')
    end
    
   
    time_slider = widget_slider(slider,title='Time',maximum = x1[ee_event],/drag,uname='time')
    pos_slider = widget_slider(slider,title='Slit Position',maximum = y1[ee_event],/drag,uname='position')
    plot_window = widget_base(base,/column)
    line_plot = widget_window(plot_window,xsize=500,ysize=300,uname='P1')
    line_plot2 = widget_window(plot_window,xsize=500,ysize=300,uname='P2')
    
    

    widget_control, base, /realize

    XMANAGER, 'ee_explore', base
end



