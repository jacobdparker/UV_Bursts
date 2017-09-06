;description is in the name

;is it rapper or wrapper?
 ; logo = read_png('rapping_mouse.png')
  ;logosize=size(logo)
  ;nxlogo = logosize[2]
  ;nylogo = logosize[3]
 ; window, 13, xsize=nxlogo, ysize=nylogo, title="Did you say Mouse Rapper?"
  ;tv, logo, /true
  
restore,'ee_obs_paths.sav'
restore, 'where_boxes.sav'

  if file_search('ee_wrapper_state.sav') eq "" then wrapper_state = 0 else begin
     restore,'ee_wrapper_state.sav'
  endelse

 
  
  while wrapper_state lt n_elements(ee_obs_path) do begin
     ee_dir  = ee_obs_path[wrapper_state] 
     ee_gunzip, ee_dir, data_path
;Check if the ee.sav file already exists
     eetime=strmid(ee_dir, 51, 5)
     if file_search(data_path,'ee_'+eetime+'_15.sav') ne "" then resume = 1 else resume = 0
     eemouse,startdir = data_path,resume = resume,wrapper_state=wrapper_state,where_box=where_boxes[wrapper_state]
        
  
     STOP,'Type .c if you are done with a given OBS.'
     wrapper_state +=1
     save,wrapper_state,file='ee_wrapper_state.sav'
     ee_dataclear,ee_dir
;This simply renames the ee.sav file with a data in case there were
;multiple obs on one day.
     file_move,data_path+'ee.sav',data_path+'ee'+strmid(ee_dir,17,6,/reverse_offset)+'_15.sav'
     STOP,'If you would like to select more events press .c otherwise just close the terminal.'

  endwhile
 
  
  
end

  
