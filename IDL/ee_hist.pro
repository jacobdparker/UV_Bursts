;PROCEDURE: ee_hist
;PURPOSE: create assorted histograms for IRIS data
;PARAMETERS:
;  dat_array=array containing box dimension data for ee.sav files
;  dates=the dates of the observation images
;  counts=the number of boxes per image
;VARIABLES:
;  depth=number of observations
;  lengths=the length of the boxes in hours
;  heights=the heights of the boxes in arcsec
;  timefiles,fitsheads=files containing real observation times and
;                      header info
;  obs,i=counting variables
;  countsum=array containing the sum of boxes drawn with each
;           additional image
;  char=character for routine selection
;  p,p1,p2=plots
;  l1,l2,x1,x2,y1,y2=linear fit for gaussian peak (since sharp)
;  gauss=gaussian fit of cumulative histogram
;  dt,sigd=derivative and error of cumulative histogram
;  h_peak=height of gaussian peak from its base
;  loc1,loc2=location of half heights of gaussian peak
;  w_half=gaussian peak width at half height
;PRODUCES: histogram plots
;AUTHOR(S): A.E. Bartz 6/19/17

pro ee_hist, dat_array, dates, counts

  depth=n_elements(counts)
  lengths=[]
  heights=[]
  timefiles=file_search('../EE_Data','dateobs*.sav')
  fitsheads=file_search('../EE_Data','obsinfo*.sav')
  
;Assign data arrays
  for obs=0,depth-1 do begin
     x0=dat_array[*,0,obs]
     x1=dat_array[*,1,obs]
     y0=dat_array[*,2,obs]
     y1=dat_array[*,3,obs]

;Crop data arrays to actual number of events
     x0=x0[0:(counts[obs]-1)]
     x1=x1[0:(counts[obs]-1)]
     y0=y0[0:(counts[obs]-1)]
     y1=y1[0:(counts[obs]-1)]

;Send data into larger arrays
     lengths=[lengths,ee_boxlength(x0,x1,timefiles[obs])]
     heights=[heights,ee_boxheights(y0,y1,fitsheads[obs])]
  endfor

  h_len=histogram(lengths, binsize=0.005, locations=bins_len)
  p_len=total(h_len, /CUMULATIVE)/n_elements(lengths)

  h_hgt=histogram(heights, locations=bins_hgt)
  p_hgt=total(h_hgt, /CUMULATIVE)/n_elements(heights)
  
;Histograms: which to produce?
  i=0
  while i eq 0 do begin

     char=''
     print, format='(%"\nHISTOGRAMS\nWhich plot do you want to produce?")'
     print, format='(%"h - cumulative histogram of box height\nl - cumulative histogram of box length times\ng - gaussian fit of cumulative histogram derivative\nq - quit and return to kernel")'
     read, char, prompt="Type your selection here: "

     case char of
        'h': begin
           p=plot(bins_hgt,p_hgt,/WIDGETS,ytitle="dp/dx",$
                  xtitle="Height of boxes (arcsec)",$
                  title="Cumulative histogram of box heights")
        end

        'd': begin
           ;Calculate and plot derivative
           dt=deriv(bins_hgt,p_hgt)
           sigd=derivsig(bins_hgt,p_hgt,0,0.1)
           p=plot(bins_hgt,dt,/WIDGETS,ytitle="dp/dx",$
                  xtitle="Height of boxes (arcsec)",$
                  title="Cumulative histogram derivative")
           ;Calculate gaussian fit, peak location, and add to plot
           gauss=gaussfit(bins_hgt,dt,yerror=yerror,sigma=sigma,nterms=6,$
                          measure_errors=measure_errors,chisq=chisq)
           p=plot(bins_hgt,gauss,/OVERPLOT, '-r')
           mx=where(gauss eq max(gauss))
           t=text(80,0.022,/DATA,"Gaussian fit with nterms=6 and peak of "+$
                  strcompress(bins_hgt[mx])+" arcsec",'r',font_size=8.5)
        end
        
        'g': begin
           ;Calculate and plot derivative
           dt=deriv(bins_len,p_len)
           sigd=derivsig(bins_len,p_len,0,0.1)
           p=plot(bins_len,dt,/WIDGETS,ytitle="dp/dx",$
                  xtitle="Time length of boxes (hours)",$
                  title="Cumulative histogram derivative")
           ;Calculate gaussian fit, peak location, and add to plot
           gauss=gaussfit(bins_len,dt,yerror=yerror,sigma=sigma,nterms=4,$
                          measure_errors=measure_errors,chisq=chisq)
           p=plot(bins_len,gauss,/OVERPLOT, '-r')
           mx=where(gauss eq max(gauss))
           t=text(0.4,6, "Gaussian fit with nterms=4 and peak of "+$
                  strcompress(bins_len[mx])+" hours",/DATA,'r',font_size=8.5)
        end

        'l': begin
                                ;Cumulative histogram of box length
           p=plot(bins_len,p_len, $
                  title="Cumulative histogram of box times", $
                  xtitle="Time length of box", $
                  ytitle="Cumulative frequency of box time")
        end
        
        'q': i=1
        else: print, 'Invalid input.'

     endcase
  endwhile
  print, "Returning to kernel..."
end
