load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCLPATH/get_environment.ncl"
load "$NCLPATH/pop_lon_shift.ncl"
load "$NCLPATH/pop_eq_avg.ncl"
begin
   fileid = addfile(file_netcdf,"r")

   ocn_comp = getenv("OCN_COMP")
   if (ocn_comp.eq."MOM") then
     temp = fileid->temp(0,:,:,:)
   else ; POP
     temp = fileid->TEMP(0,:,:,:)
   end if

   if (isatt(temp,"_FillValue"))
      missing = temp@_FillValue
   else
      missing = 1e30
   end if
   units = temp@units
   
   
   print(isvar("grid_file"))
   print(isfilepresent(grid_file))

   if (isvar("grid_file") .and. isfilepresent(grid_file)) then
     gridid = addfile(grid_file,"r")
     tlon = gridid->TLONG
     tlat = gridid->TLAT
   else
     if (ocn_comp.eq."MOM") then
       dout_s_root = getenv("DOUT_S_ROOT")
       ocn_geo_file = addfile(dout_s_root+"/ocn/hist/ocean_geometry.nc","r")
       tlon = ocn_geo_file->geolon
       tlat = ocn_geo_file->geolat
     else ; POP
       tlon = fileid->TLONG
       tlat = fileid->TLAT
     end if
   end if
   size = dimsizes(tlon)
   nx = size(1)
   ny = size(0)

   if (ocn_comp.eq."MOM") then
     gridInfoFilePath = getenv("DIAGOBSROOT")+"/omwg/za_grids/"+getenv("RESOLUTION")+"_grid_info.nc"
     gridInfoFile = addfile(gridInfoFilePath,"r")
     kmt = gridInfoFile->KMT
     region_mask = kmt ; TODO: fix_this !!!
     z_t = fileid->z_l
     nz = dimsizes(z_t)
   else ; POP
     kmt = fileid->KMT
     kmu = fileid->KMU
     region_mask = fileid->REGION_MASK
     z_t = fileid->z_t
     nz = dimsizes(z_t)
     z_t = z_t / 100.
   end if
   z_max = ind_nearest_coord(500.0,z_t,0)
   
   fileidobs = addfile(file_T_obs,"r")
   temp_obs = fileidobs->TEMP

   y_eq = ind_nearest_coord(0,tlat(:,0),0)
   east30 = ind_nearest_coord(30,tlon(y_eq,:),0)

   tlat = pop_lon_shift(tlat,east30)
   tlon =  pop_lon_shift(tlon,east30)
   field =  pop_lon_shift(temp,east30)
   field_obs = pop_lon_shift(temp_obs,east30)
   temp1 = pop_eq_avg(field,y_eq-1,y_eq,missing)
   
   temp1_obs = pop_eq_avg(field_obs,y_eq-1,y_eq,missing)
   temp1_diff = temp1 - temp1_obs
   tlon_eq = tlon(y_eq,:)
   tlon_eq = where(tlon_eq .lt. 30, tlon_eq + 360, tlon_eq)
   
   dmin      =   2.
   dmax      =  32.
   dmin_diff = -15.
   dmax_diff =  15.
   nlev      =  31 
   dlev = (dmax-dmin)/(nlev-1) 
   lev  = dmin + ispan(0,nlev-1,1)*dlev
   dlev_diff = (dmax_diff-dmin_diff)/(nlev-1) 
   lev_diff  = dmin_diff + ispan(0,nlev-1,1)*dlev_diff
   
   coltab = new(nlev + 1,"integer")
   coltab(0) = 1
   color1 = 2 
   coltab(1:) = ((color2-color1+1)/(nlev-1))*ispan(0,nlev-1,1)+color1
   coltab(0) = 0
   
   case_info = "TEMP AT EQ " + case_number + " " + time_info
   case_info_diff = "MODEL - LEVITUS/PHC2" 

   print("plotting equatorial TEMP")
   ;wks = gsn_open_wks("x11","T_EQ")
   wks = gsn_open_wks(img_format,"T_EQ")
   gsn_define_colormap(wks,"table42")
   
   res = True
   res@gsnDraw = False
   res@gsnFrame = False
   res@sfYArray = z_t(:z_max)
   res@sfXArray = tlon_eq
   res@cnFillOn = True
   res@cnFillMode = "RasterFill"
   res@cnInfoLabelOn = False
   res@cnLineLabelPlacementMode = "constant"
   res@cnRasterSmoothingOn = True
   res@cnLevelSelectionMode = "explicitLevels"
   res@cnLevels = lev
   res@cnFillColors = coltab
   res@lbLabelBarOn = False
   res@tmXBLabelsOn = False
   res@tiYAxisString = "DEPTH (m)"
   res@tiYAxisFontHeightF = .025
   res@gsnYAxisIrregular2Linear = True
   res@gsnCenterString = case_info
   res@vpWidthF = 0.9
   res@trYReverse = True
   res@trYMaxF = 400.0
   res@trYMinF = 0.0
   plot1 = gsn_csm_contour(wks,temp1(:z_max,:),res)  

   res@cnLevels = lev_diff
   res@gsnCenterString = case_info_diff
   res@tmXBLabelsOn = True
   res@tmXBMode = "explicit"
   res@tmXBValues = (/ 100, 200, 300 /)
   res@tmXBMinorValues = (/ 40, 60, 80, 120, 140, 160, 180, 220, 240, 260, 280, 320, 340, 360, 380 /)
   res@tmXBLabels = (/ "100~S~o~N~E", "200~S~o~N~E", "300~S~o~N~E" /)
   plot2 = gsn_csm_contour(wks,temp1_diff(:z_max,:),res)

   panel_res = True
   panel_res@gsnMaximize = True
   panel_res@gsnPaperOrientation = "portrait"
   panel_res@gsnPanelScalePlotIndex = 1
   panel_res@gsnPanelYF = (/-1,.50/)
   gsn_panel(wks,(/plot1,plot2/), (/2,1/),panel_res)

end
