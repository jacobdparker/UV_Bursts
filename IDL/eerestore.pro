;This program allows the selection of an ee.sav file that you wish to
;analyze.  It reads in the files and sets up ee common blocks.


pro eerestore, eepath, restor

  common widget_environment, img, didx, tidx, mouseread
  common eemouse_environment, rasterfile, rasterdir, sjifile, SiIV_EE_map, goodmap, goodmap_1403
  common data, si_1394_index,si_1394_data,sjiindex,sjidata,si_1403_index, si_1403_data,fe_index,fe_data

  ;; ;See if the directory has changed since last time.
  ;; if new_rasterdir ne rasterdir then begin
  ;;    rasterdir = new_rasterdir

  ;;    foo = dialog_message("Don't Panic. Apparently the directory name has changed since ee.sav was last saved. Please identify the corresponding raster and sji files. They must live in the same directory as ee.sav.",/information)

  ;;    rasterfile = dialog_pickfile(title='Select L2 Raster File', path=rasterdir)
  ;;    sjifile = dialog_pickfile(title='Select L2 SJI File', path=rasterdir)
  ;;    save, img,didx,tidx,mouseread,rasterfile,rasterdir,sjifile, SiIV_EE_map,goodmap, file = rasterdir+'ee.sav'    ;Note that all the variables & both common blocks are saved, because we 
  ;;  ;might need them to /resume later.
  ;;    foo=dialog_message('saved '+rasterdir+'ee.sav', /information)
  ;; endif

  ee_gunzip, eepath, rasterdir  

  message,'Reading SJI data...',/information
  read_iris_l2, sjifile, sjiindex, sjidata
  ;sjidata[where(sjidata eq -200)]=!values.f_nan

  message,'Reading raster data...',/information
  read_iris_l2, rasterfile, si_1394_index, si_1394_data, WAVE= 'Si IV'
  ;rasterdata[where(rasterdata eq -200)]=!values.f_nan
  read_iris_l2, rasterfile, si_1403_index, si_1403_data, wave='Si IV 1403'
  ;read_iris_l2, rasterfile, fe_index, fe_data, wave = 'O I'


;Data reduction
  message,'Despiking Si 1394...', /informational
  rasterdata = despik(si_1394_data,  sigmas=4.0, Niter=10, min_std=4.0, $
                      goodmap=goodmap, /restore) ;DESPIKE.
  message,'Removing instrumental background...', /informational
  dark_model = fuv_bg_model(si_1394_data, percentile=35, /replace) ;background subtraction
  

;Process 1403 line for calibration
  message,'Despiking Si 1403...', /informational
  if restor eq 0 then begin
 
     si_1403_data = despik(si_1403_data,  sigmas=4.0, Niter=20, $
                         min_std=4.0, goodmap=goodmap_1403) ;DESPIKE.
  endif else begin
     si_1403_data = despik(si_1403_data, sigmas=4.0, Niter=20, $
                         min_std=4.0, goodmap=goodmap_1403, /restore)
  endelse
  message,'Removing instrumental background...', /informational
  dark_model = fuv_bg_model(si_1403_data, percentile=35, /replace) ;background subtraction

  save, goodmap_1403, file=rasterdir+"goodmap1403.sav"
end
