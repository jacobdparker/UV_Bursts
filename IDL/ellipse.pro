; $Id: //depot/Release/ENVI53_IDL85/idl/idldir/lib/graphics/ellipse.pro#1 $
; Copyright (c) 2010-2015, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create an Ellipse graphic.
;
; :Params:
;    X
;    Y
;    Z
;    Style
;
; :Keywords:
;    DATA
;    VISUALIZATION
;    All other keywords are passed through to the ellipse.
;
;-
function Ellipse, x, y, z, styleIn, $
  DATA=data, DEVICE=device, NORMAL=normal, $
  POSITION=position, $
  RELATIVE=relative, TARGET=target, $
  ECCENTRICITY=eccentricity, MAJOR=major, MINOR=minor, THETA=theta, $
  DEBUG=debug, VISUALIZATION=add2vis, $
  TEST=test, $
  _REF_EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  nparams = n_params()
  if (isa(X, 'STRING'))  then $
    MESSAGE, 'Style argument must be passed in after data.'
  if (isa(Y, 'STRING'))  then begin
    if (nparams gt 2) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Y
    Y = !NULL
    nparams--  
  endif
  if (isa(Z, 'STRING')) then begin
    if (nparams gt 3) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Z
    Z = !NULL
    nparams--
  endif
  if (isa(styleIn, 'STRING')) then begin
    style = styleIn
    nparams--
  endif
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=color, LINESTYLE=linestyle, THICK=thick
  endif

  ; Check for unknown or illegal properties.
  if (N_ELEMENTS(ex) gt 0) then $
    Graphic, _EXTRA=ex, ERROR_CLASS='Ellipse', /VERIFY_KEYWORDS

  if (KEYWORD_SET(test)) then begin
    x = 0.5
    y = 0.5
  endif
  
  if (KEYWORD_SET(data) && ~ISA(add2vis)) then add2vis = 1b
  iEllipse, 0, x, y, z, $
    DATA=data, DEVICE=device, NORMAL=normal, RELATIVE=relative, TARGET=target, $
    ECCENTRICITY=eccentricity, MAJOR=major, MINOR=minor, THETA=theta, $
    VISUALIZATION=add2vis, $
    COLOR=color, LINESTYLE=linestyle, THICK=thick, $
    NAME='Ellipse', $
    OBJECT=oEllipse, $
    _EXTRA=ex

  ; Ensure that all class definitions are available.
  Graphic__define
  oGraphic = OBJ_NEW('Ellipse', oEllipse)

  if (ISA(position)) then begin
    oGraphic->_SetProperty, POSITION=position, DEVICE=device
  endif

  return, oGraphic
  
end

