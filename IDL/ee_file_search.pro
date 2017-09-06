;This script will return an array of strings containing the paths to
;desired IRIS obs
TIC
iris_data_path = '/disk/data/IRIS/archive/level2'

;Try and automate our search
one = ['*36','*38']
two = ['0','2','8']
three = ['3','4']
four = ['??']
five = ['16','14','12','11' ,'10','08','06','04','02','01','00','36','34','32','31' ,'30','28','26','24','22','21','20','56','54','52','51' ,'50','48','46','44','42','41','40','76','74','72','71' ,'70','68','66','64','62','61','60']
;six = ['2']
seven = ['0','5']
eight = ['1/','2/','3/','4/']

ee_obs = ['Start']
for a = 0,n_elements(one)-1 do begin
   for b = 0,n_elements(two)-1 do begin
      for c = 0,n_elements(three)-1 do begin
         for d = 0,n_elements(four)-1 do begin
            for e = 0,n_elements(five)-1 do begin
               ;for f = 0,n_elements(six)-1 do begin
                  for g = 0,n_elements(seven)-2 do begin ;modified to not double count obs
                     for h = 0,n_elements(eight)-1 do begin
                        
                        next_event = one[a]+two[b]+three[c]+four[d]+five[e]+seven[a]+eight[h]
                        ;+six[f]
                        ee_obs = [ee_obs,next_event]
                     end
                  end
               ;end
            end
         end
      end
   end
end






obs_sz = size(ee_obs,/structure)
  
obs_path = ""
for i = 1,obs_sz.n_elements-1 do begin
   next_path = file_search(iris_data_path,ee_obs[i],/test_directory)
   obs_path = [obs_path,next_path] 
end
ee_obs_path = obs_path(where(obs_path ne ""))

save,ee_obs_path,filename = "ee_obs_paths.sav"

  
TOC
end
