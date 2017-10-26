pro ee_gunzip, ee_dir, data_path
date = strmid(ee_dir,30,12)
data_path = file_expand_path('eemouse.pro')
data_path = strmid(data_path,0,strlen(data_path)-14) ;only works if EE files are stored in a directory called EE, could be more robust
data_path = data_path+'EE_Data'+date
data = file_search(ee_dir,'*fits.gz')
file_mkdir,data_path


for i = 0,n_elements(data)-1 do begin
   
   unzip_data = strmid(data[i],strlen(ee_dir),strlen(data[i])-strlen(ee_dir)-strlen('.gz'))

   ;avoid uncompressing data over and over again during testing
   if file_search(data_path+unzip_data) eq "" then begin
    
      print,'Unpacking '+unzip_data
      file_gunzip, data[i],data_path+unzip_data
   end
   
  
   
end



end

