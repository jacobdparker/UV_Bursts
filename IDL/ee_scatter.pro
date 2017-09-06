;PROCEDURE: ee_scatter
;PURPOSE: produce scatter plots of IRIS box length data
;PARAMETERS:
;  dat_array=array containing image data
;  dates=the dates of the observations
;  counts=the number of boxes drawn per image
;VARIABLES:
;  timefiles,fitsheads=paths to files containing time and header info
;  depth=number of observations
;  heights,lengths=arrays of heights and lengths of events in arcsec
;                  and hours
;  avg_heights, avg_lengths=array of average heights and lengths of an
;                           event during each observation in arcsec
;                           and hours
;  dev_heights,dev_lengths=array of standard deviations of heights and
;                          lengths of each event during each observation
;  obs,i=counting variable
;  x0,x1,y0,y1=temporary arrays containing top and bottom position
;  p=scatter plot
;  fitline,fitx,fity=linear fit for scatter plot
;  r=pearson correlation coefficient
;  fitext,t1,t2=text containing fit line and correlation coefficient
;PRODUCES: scatter plots of box height vs box length, position of events on
;          solar disk
;AUTHOR(S): A.E. Bartz 6/16/17

pro ee_scatter, dat_array, dates, counts

;Initialize arrays & find observation time filepaths
  depth=n_elements(counts)-4
  lengths=[]
  heights=[]
  avg_lens=fltarr(depth)
  avg_heights=fltarr(depth)
  timefiles=file_search('../EE_Data','dateobs*.sav')
  fitsheads=file_search('../EE_Data','obsinfo*.sav')
  
;Compute arrays containing each event's length and the average
;length in time order
  for obs=0,depth-1 do begin
     x0=dat_array[*,0,obs]
     x1=dat_array[*,1,obs]
     y0=dat_array[*,2,obs]
     y1=dat_array[*,3,obs]
     
;Crop data arrays to actual number of events to omit extra zeroes
     x0=x0[0:counts[obs]]
     x1=x1[0:counts[obs]]
     y0=y0[0:counts[obs]]
     y1=y1[0:counts[obs]]
     
;Compute average length of time of events and standard deviations     
     obs_lens=ee_boxlength(x0,x1,timefiles[obs])
     obs_heights=ee_boxheights(y0,y1,fitsheads[obs])
     lengths=[lengths,obs_lens]
     heights=[heights,obs_heights]
     avg_lens[obs]=mean(obs_lens)
     avg_heights[obs]=mean(obs_heights)
  endfor
  
;User interactive: Which plots do you want to produce?
  i=0
  while i eq 0 do begin    
     val=''
     print, format='(%"\nSCATTERPLOTS\nWhich plot do you want to produce?")'
     print, format='(%"d - position of observations on the solar disk\nl - box height vs. box length\nq - quit and return to the kernel")'
     read, val, prompt='Type your selection here: '

     case val of
        'q': i=1
        
        'l': begin
                                ;Make plot
           p=plot(lengths,heights, /WIDGETS, linestyle=6, symbol='o',$
                  /sym_filled, sym_transparency=50, rgb_table=43, $
                  title='Height of boxes versus length of boxes', $
                  xtitle='Time length of boxes (hours)', $
                  ytitle='Slit height of boxes (arcsec)',/buffer)

           ;;                      ;Add trend line
           ;; fitline=linfit(lengths,heights, CHISQR=chisqr, COVAR=covar, $
           ;;                PROB=prob, SIGMA=sigma, measure_errors=measure, $
           ;;                YFIT=yfit)
           ;; fitx=findgen(100,increment=0.02)
           ;; fity=fitline[0]+fitx*fitline[1]
           ;; linplot=plot(fitx,fity, /OVERPLOT, color="red", thick=2, $
           ;;              linestyle=3, yrange=[0,225])
           ;;                      ;Add trend line equation text
           ;; fitext=strcompress(string(fitline),/remove_all)
           ;; r=correlate(lengths,heights)
           ;; t1=text(1.25,50,/DATA,'Y='+fitext[0]+'+'+fitext[1]+'X',$
           ;;         font_size=8,'r')
           ;; t2=text(1.25,35,/DATA,'r='+strcompress(string(r),/remove_all),$
           ;;         'r',font_size=8)

           ;Calculate general box statistics
           indices=where(lengths lt 0.5 AND heights lt 30)
           print, string(mean(lengths[indices]))+" hours"+string(stdev(lengths[indices]))
           print, string(mean(heights[indices]))+" arcsec"+string(stdev(heights[indices]))
        end 

        'd': ee_discplot, lengths, heights, dates, counts, fitsheads, $
                          timefiles, avg_lens, avg_heights
        
        else: print, "Invalid input."
     endcase
  endwhile
  print, "Returning to kernel."

end
