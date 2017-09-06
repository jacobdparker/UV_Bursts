;Test of LINE_QUARTILES.
;
;CCK 2014-Jun-27

;Produce fake data (profile as a function of lambda).
N = 64
lambda = findgen(N) - N/2
sigma = 10.0
maxcounts = 10.0
profile = maxcounts * exp(-lambda^2/(2*sigma^2))
profile_noiseless = profile
pnoise, profile, seed=seed

;Analyze with LINE_QUARTILES.
quartiles = line_quartiles(profile, lambda, /spline)

centroid = total(lambda*profile)/total(profile)

plot, lambda, profile, psym=10
oplot, lambda, profile_noiseless, linestyle=2
for i=0,2 do begin
   oplot, [quartiles[i],quartiles[i]], [0,maxcounts], linestyle=1
endfor
oplot, [centroid, centroid], [0,2*maxcounts], linestyle=3
print, quartiles
print, 'Q13 width = ', quartiles[2] - quartiles[0]
ssw_legend, ['simulated data','ideal profile','quartiles','centroid'], linestyle=[0,2,1,3]
end