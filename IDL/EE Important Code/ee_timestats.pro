;PROGRAM: ee_timestats
;PURPOSE: compute time length of image boxes and plot against
;         different values
;PARAMETERS:
;  dat_array=4x100x31 array containing dimension data for event boxes
;  dates=array of Julian dates of each observation
;  counts=array of number of boxes in each image
;VARIABLES:
;  depth=number of observations
;  lengths=2D array of lengths of each event in each observation
;  avg_lens=array of average length of time of an event during each
;     observation
;  dev_lens=array of standard deviations of lengths of each event
;     during each observation
;  obs,i,n=counting variable
;  x0,x1=temporary arrays containing beginning and ending time
;  timefiles=filepaths leading to actual observation times
;  char=character variable for plot/computation selection
;PRODUCES: plots
;AUTHOR(S): A.E. Bartz, 6/9/17
pro ee_timestats, dat_array, dates, counts
;Initialize arrays & find observation time filepaths
  depth=n_elements(counts)
  lengths=fltarr(100,depth)
  avg_lens=fltarr(depth)
  dev_lens=fltarr(depth)
  timefiles=file_search('../EE_Data','dateobs*.sav')
  
;Compute arrays containing each event's length and the average length
  for obs=0,depth-1 do begin
     x0=dat_array[*,0,obs]
     x1=dat_array[*,1,obs]
     
;Crop data arrays to actual number of events to omit extra zeroes
     x0=x0[0:counts[obs]]
     x1=x1[0:counts[obs]]
     
;Compute average length of time of events and standard deviations     
     obs_lens=ee_boxlength(x0,x1,timefiles[obs])
     avg_lens[obs]=mean(obs_lens)
     dev_lens[obs]=stddev(obs_lens)
     lengths[0,obs]=obs_lens
  endfor

  
;Compute & print average length of time for all events
  print, "The average time of an event for all observations is "+$
         strcompress(mean(avg_lens),/Remove_all)+' hours with standard '+$
         'deviation of '+strcompress(stddev(avg_lens),/remove_all)+' hours'

;User interactive: Which plots do you want to produce?
  i=0
  while i eq 0 do begin
     
     char=''
     print, format='(%"\nWhich plot do you want to produce?")'
     print, format='(%"a - average box time length of each observation\nb - number and average size of boxes by date\nl - time length of all boxes in all observations\nq - quit and return to kernel")'
     read, char, prompt='Type your selection here: '

     case char of
        'a': begin
;Plot the average length of each box per date
           p=plot(dates, avg_lens, symbol='o', /sym_filled, rgb_table=41, $
                  linestyle=6, xtitle="Julian date", $
                  ytitle="Average length of a box (hours)", $
                  title="Average time length of event box by image")
        end

        'l': begin
;Plot the length of each box against date,toggle with/without error bars
           b=plot(make_array(counts[0],value=dates[0]), $
                  lengths[0:counts[0],0], $
                  /WIDGETS, symbol='o', /sym_filled, linestyle=6, $
                  rgb_table=43,sym_transparency=50,$
                  xrange=[dates[0]-50,dates[-1]+50], xtickinterval=365, $
                  xtitle='Julian date',ytitle='Hours',$
                  title='Time length of all event boxes')
           for n=1,31 do begin
              b=plot(make_array(counts[n],value=dates[n]), $
                     lengths[0:counts[n],n], $
                     symbol='o', /sym_filled, rgb_table=43, linestyle=6,$
                     sym_transparency=50,/OVERPLOT)
           endfor
        end

        'b': begin
;Plot number of boxes against date where size of point corresponds to
;average length
           mn=min(avg_lens)
           scale=2.0/(max(avg_lens)-mn)
           p=plot([dates[0]],[counts[0]],/widgets,symbol='o',linestyle=6, $
                  sym_transparency=50, xtitle="Julian date", $
                  ytitle="Box count", yrange=[0,max(counts)+5],$
                  sym_size=0.5+(avg_lens[0]-mn)*scale, $
                  sym_color=[0,255,0], xrange=[dates[0]-50,dates[-1]+50],$
                  title="Box count and length of time")
           for n=1,depth-1 do begin
              p=plot([dates[n]],[counts[n]],/overplot, linestyle=6, $
                     symbol='o', sym_size=1.5+(avg_lens[n]-mn)*scale, $
                     sym_color=[0,255,255*n/(depth-1)])
           endfor
        end
        
        'q': i=1

        else: print, "Invalid input."
     endcase
  endwhile
  print, 'Returning to kernel...'
end
