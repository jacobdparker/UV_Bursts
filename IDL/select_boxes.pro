;------------------------------------------------------------------------------

pro show_image

  common widget_environment, img, didx, tidx, mouseread

  wset, didx.img

  ;tv, bytscl(rebin(img.image, img.scl*img.nx, img.scl*img.ny), img.i0, img.i1)
  tv, bytscl(downsample(img.image, img.scl*img.nx, img.scl*img.ny), img.i0, img.i1)
  if mouseread.count gt 0 then begin
     for i=0,mouseread.count-1 do $
        plot, [mouseread.x0[i], mouseread.x1[i], $
               mouseread.x1[i], mouseread.x0[i], mouseread.x0[i]],$
              [mouseread.y0[i], mouseread.y0[i], $
               mouseread.y1[i], mouseread.y1[i], mouseread.y0[i]],$
              color=mouseread.color[i], linestyle=mouseread.style[i], $
              xstyle=13, ystyle=13, xmargin=[0,0], ymargin=[0,0], $
              xran=[0,img.nx-1], yran=[0,img.ny-1], /noerase
  endif
end

;------------------------------------------------------------------------------

pro table_event_handler, event

  common widget_environment, img, didx, tidx, mouseread

  stash=widget_info(event.handler, /child)
  WIDGET_CONTROL, stash, get_uvalue=state

  widget_control, event.id, get_uvalue=action

  CASE action OF
     'TABLE' : BEGIN
        ;identify the kind of table event
        table_event=tag_names(event, /STRUCTURE_NAME)
        ;message, 'table_event: '+table_event, /informational
        case table_event of
           ;if row is selected, highlight, change plotted linestyle
           'WIDGET_TABLE_CELL_SEL' : begin
               info=widget_info(tidx.table, /TABLE_SELECT)
               col=info[0]
               row=info[1]
               mouseread.style[row]=2
               show_image
               mouseread.style[row]=0
           end

           ;if entry is edited, update plot (CCK)
           'WIDGET_TABLE_CH' : begin
               info=widget_info(tidx.table, /TABLE_SELECT)
               col=info[0]
               row=info[1]
               if row gt mouseread.count then break
               if row eq mouseread.count then begin ;Manual row entry feature!
                  mouseread.count = mouseread.count + 1
               endif               
               widget_control, tidx.table, get_value=selection_value, /use_table_select
               case col of
                  0: begin
                     mouseread.x0[row] = selection_value
                     print,'x0 = ',selection_value
                  end
                  1: begin
                     mouseread.x1[row] = selection_value
                     print,'x1 = ',selection_value
                  end
                  2: begin
                     mouseread.y0[row] = selection_value
                     print,'y0 = ',selection_value
                  end
                  3: begin
                     mouseread.y1[row] = selection_value
                     print,'y1 = ',selection_value
                  end
                  ELSE: break
               endcase
               ;rectify_mouseread ;This interfered with interactive editing! CCK.
               show_image
           end
           
           ELSE: break
        endcase
     END

     ;if entry is deleted, update plot
     'DELETE' : BEGIN
        info=widget_info(tidx.table, /TABLE_SELECT)
        row=info[1]
        if row ge mouseread.count then break ;Can't delete rows that do not exist! CCK

        mouseread.x0[row:98]=mouseread.x0[row+1:99]
        mouseread.x1[row:98]=mouseread.x1[row+1:99]
        mouseread.y0[row:98]=mouseread.y0[row+1:99]
        mouseread.y1[row:98]=mouseread.y1[row+1:99]
        mouseread.color[row:98]=mouseread.color[row+1:99]

        mouseread.x0[99]=0 & mouseread.x1[99]=0
        mouseread.y0[99]=0 & mouseread.y1[99]=0
        mouseread.color[99]=0

        widget_control, tidx.table, $ ;table_xsize=4, table_ysize=100, $
                        set_value=transpose([[mouseread.x0], $
                                             [mouseread.x1], $
                                             [mouseread.y0], $
                                             [mouseread.y1]])
        mouseread.count=mouseread.count-1

        show_image
     END

  ENDCASE

end

;------------------------------------------------------------------------------

pro table_widget_setup

  common widget_environment, img, didx, tidx, mouseread

  basewidget = widget_base(TITLE='Coordinate Table', /column)

  table=widget_table(basewidget, $
                     /editable, /ALL_EVENTS, $
                     column_labels=['X0','X1','Y0','Y1'], $
                     xsize=4, y_scroll_size=20, $
                     UVALUE='TABLE', $
                     value=transpose([[mouseread.x0], $
                                      [mouseread.x1], $
                                      [mouseread.y0], $
                                      [mouseread.y1]]), $
                     format='(I4)', alignment=1, background_color=[223,223,223])

  button=widget_button(basewidget, Value='Delete Entry', uvalue='DELETE')

  tidx={base:basewidget, table:table}

end

;------------------------------------------------------------------------------
pro rectify_mouseread ;CCK. Make sure x1>x0, y1>y0.
   common widget_environment, img, didx, tidx, mouseread
   ss = where(mouseread.x1 lt mouseread.x0)
   if ss[0] ne -1 then begin
      temp = mouseread.x1[ss]
      mouseread.x1[ss] = mouseread.x0[ss]
      mouseread.x0[ss] = temp
   endif
   ss = where(mouseread.y1 lt mouseread.y0)
   if ss[0] ne -1 then begin
      temp = mouseread.y1[ss]
      mouseread.y1[ss] = mouseread.y0[ss]
      mouseread.y0[ss] = temp
   endif
   ;Now redraw the table for consistency.
   widget_control, tidx.table, $ ;table_xsize=4, table_ysize=100, $
               set_value=transpose([[mouseread.x0], $
                                    [mouseread.x1], $
                                    [mouseread.y0], $
                                    [mouseread.y1]])

end
;------------------------------------------------------------------------------
pro save_mouseread  ;CCK. Save mouseread structure in current directory.
   common widget_environment, img, didx, tidx, mouseread
   rectify_mouseread
   save, mouseread, file='mouseread.sav'
   foo=dialog_message('Saved '+curdir()+'/mouseread.sav', /information)
end
;------------------------------------------------------------------------------

pro display_event_handler, event

  common widget_environment, img, didx, tidx, mouseread

  stash=widget_info(event.handler, /child)
  WIDGET_CONTROL, stash, get_uvalue=state

  widget_control, event.id, get_uvalue=action

  CASE action OF
     'EXIT' : begin
        case dialog_message("Save before quitting?", /question, /cancel) of ;CCK
           'Cancel': cancel=1 ;Don't quit afterall
           'Yes': save_mouseread
           'No': begin
                 ;message,"Don't say I didn't warn you!",/informational
              end
           ELSE: break
        endcase
        if keyword_set(cancel) then break
        WIDGET_CONTROL, didx.base, /DESTROY

        ;reset color and plot options to original
        !p.font=didx.font
        device, decomposed=didx.color
        RETURN
     end
     
     'SAVE' : begin ;CCK save function
        save_mouseread
     end

     'DISPLAY' : begin
        i=mouseread.count

        ;on press
        if event.press eq 1 then begin
           mouseread.down=1

           ;store initial coordinates
           mouseread.x0[i]=event.x/img.scl
           mouseread.y0[i]=event.y/img.scl

           ;randomly generate box color
           rand=(randomu(seed,3)+0.75)*255/1.75
           mouseread.color[i]=rand[0] + 256L * (rand[1] + 256L * rand[2])
        endif

        ;on move
        if mouseread.down eq 1 then begin
           ;refresh image
           show_image

           ;plot box
           plot, [mouseread.x0[i], event.x/img.scl, event.x/img.scl, $
                  mouseread.x0[i], mouseread.x0[i]], $
                 [mouseread.y0[i], mouseread.y0[i], $
                  event.y/img.scl, event.y/img.scl, mouseread.y0[i]],$
                 color=mouseread.color[i], $
                 xstyle=13, ystyle=13, xmargin=[0,0], ymargin=[0,0], $
                 xran=[0,img.nx-1], yran=[0,img.ny-1], /noerase

        endif

        ;on release, store final [x1,y1], stop drawing
        if event.release eq 1 then begin
           ;reset flag
           mouseread.down=0

           ;store final coordinates
           mouseread.x1[i]=max([mouseread.x0[i],event.x/img.scl])
           mouseread.x0[i]=min([mouseread.x0[i],event.x/img.scl])

           mouseread.y1[i]=max([mouseread.y0[i],event.y/img.scl])
           mouseread.y0[i]=min([mouseread.y0[i],event.y/img.scl])

           ;update table
           widget_control, tidx.table, $
                           set_value=transpose([[mouseread.x0], $
                                                [mouseread.x1], $
                                                [mouseread.y0], $
                                                [mouseread.y1]])

           ;update count
           mouseread.count=i+1

           show_image
        endif

     end
  endcase

end

;------------------------------------------------------------------------------

pro display_widget_setup

  common widget_environment, img, didx, tidx, mouseread

  basewidget = widget_base(TITLE='Display', /row)

  drawwidget = widget_draw(basewidget, uvalue='DISPLAY', $
                           xsize=img.nx*img.scl, ysize=img.ny*img.scl, $
                           /MOTION_EVENT, /BUTTON_EVENTS, retain=2)

  buttonbar=widget_base(basewidget, /column)
  button = widget_button(buttonbar, Value='Save', uvalue='SAVE')
  button = widget_button(buttonbar, Value='Exit', uvalue='EXIT')

  didx = {base:basewidget, draw:drawwidget, img:0L, font:0L, color:0L}

end

;------------------------------------------------------------------------------

;make a draw widget, and interactively select multiple boxes
pro select_boxes, image, scl=scl

  common widget_environment, img, didx, tidx, mouseread

  if keyword_set(image) ne 1 then image=findgen(200,200)

  ;get image size
  nx=(size(image))[1]
  ny=(size(image))[2]

  ;determine image rescale factor for user display unless scaling is set
  if keyword_set(scl) ne 1 then begin
     ss=get_screen_size()

     if nx gt 0.9*ss[0] or ny gt 0.9*ss[1] $
     then scl=max(ceil([nx/float(ss[0]), ny/float(ss[1])])) $
     else scl=1
  endif

  ;setup image information structure
  img = {image:image, nx:nx, ny:ny, scl:scl, $
         i0:min(image,/nan), i1:max(image,/nan)}

  ;store color and plot options that will be overridden
  font=!p.font
  device, get_decomposed=decomp

  ;override color and plot options for widget displays
  !p.font=-1
  device, decomposed=1
  device, retain=2

  ;set mouse flags for display widget handler
  mouseread={down:0, psym:0, count:0, color:intarr(100), style:intarr(100), $
             x0:intarr(100), y0:intarr(100), x1:intarr(100), y1:intarr(100)}

  display_widget_setup
  table_widget_setup

  widget_control, didx.base, /REALIZE
  widget_control, tidx.base, /realize

  ;get window indices for image displays
  WIDGET_CONTROL, GET_VALUE=disp_img, didx.draw

  didx.img=disp_img
  didx.font=font
  didx.color=decomp

  show_image

  xmanager, 'display_widget', didx.base, $
            event_handler='display_event_handler', /no_block
  xmanager, 'table_widget', tidx.base, group_leader=didx.base, $
            event_handler='table_event_handler', /no_block
end
