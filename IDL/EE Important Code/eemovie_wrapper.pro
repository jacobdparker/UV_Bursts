restore, 'ee_obs_paths.sav'
  
  for i = 0,n_elements(ee_obs_path)-1 do begin
   
     print,i
     if ((i eq 2) or (i eq 6) or (i eq 20) or (i eq 26)) then continue

     ee_dir=ee_obs_path[i]
     ee_gunzip, ee_dir, data_path
     eemovie, eepath=[data_path, ee_dir], /ffmpeg, /quiet
     ee_dataclear, ee_dir
  endfor

end
