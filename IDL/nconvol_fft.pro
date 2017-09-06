; Name:
;   NCONVOL_FFT
;
; Purpose:
;   Convolution of an image using Fourier transforms for speed
;       
; Parameters:
;   IMAGE: ND array to be convolved with the kernel
;       
;   KERNEL: ND array (size < or = to size of image)
;

;-
function nconvol_fft, image, kernel, $
                     AUTO_CORRELATION=auto, CORRELATE=corr, NO_PADDING=noPad, $
                     IMAGE_FFT=imageFFT, KERNEL_FFT=kernelFFT



;  Begin attempted modifications for N-dimensions, for now limited to
;  convolution, maybe later I will include correlation
  imagesz = size(image,/structure)
  imageDims2 = FLOOR((imagesz.dimensions-1)/2)
 
   
; Pad image with zeros in a way that each dimension is a multiple of 2


  imageDims=imagesz.dimensions
  multoftwo = 2^(indgen(10)+5)
  padsize = intarr(imagesz.n_dimensions)
  
  for i = 0,imagesz.n_dimensions-1 do begin
     padsize[i] = multoftwo[min(where(multoftwo-imagedims[i]*2 ge 0))]
  end

  bigImage = fltarr(padsize)
;theres got to be a slicker way to do this
  case imagesz.n_dimensions of
     2: bigImage[0,0] = image
     3: bigImage[0,0,0] = image
     4: bigImage[0,0,0,0] = image
  end
  image=0
  
  

  bigImage = FFT(bigImage,-1,/overwrite)

  imageNElts = N_ELEMENTS(bigImage)
TOC

  kernelSz = size(kernel, /STRUCTURE)
    
  loc = (imageDims2 - floor((kernelsz.dimensions-1)/2)) > 0
 
  kernelTemp = fltarr(padsize)
  case imagesz.n_dimensions of
     2: kernelTemp[loc[0], loc[1]] = kernel
     3: kernelTemp[loc[0], loc[1], loc[2]] = kernel
     4: kernelTemp[loc[0], loc[1], loc[2], loc[3]] = kernel
  end
  kernel = 0
  
  kerneltemp = FFT(kernelTemp, -1,/overwrite)

    
    
  conv = imageNElts*REAL_PART(FFT(temporary(bigimage)*temporary(kerneltemp), 1))
  case imagesz.n_dimensions of
     3: conv = SHIFT(temporary(conv), -imageDims2[0], -imageDims2[1], -imageDims2[2])
  end

 
    
    return, conv[0:imageDims[0]-1,0:imageDims[1]-1]
  
  
end
