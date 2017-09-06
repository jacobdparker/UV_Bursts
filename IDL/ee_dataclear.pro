pro ee_dataclear, ee_dir
date = strmid(ee_dir,30,12)
data_path = file_expand_path('eemouse.pro')
data_path = strmid(data_path,0,strlen(data_path)-14) ;only works if EE files are stored in a directory called EE, could be more robust
data_path = data_path+'EE_Data/'+date
data = file_search(ee_dir,'*fits.gz')


for i = 0,n_elements(data)-1 do begin
   
   unzip_data = strmid(data[i],strlen(ee_dir),strlen(data[i])-strlen(ee_dir)-strlen('.gz'))
   file_delete,data_path+unzip_data
end



end
