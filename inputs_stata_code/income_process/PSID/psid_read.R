rm(list=ls())
library(psidR)
library(data.table)
library(foreign)
library(openxlsx)
install.packages("psidR")
# NOTE: build the panel from a local, non-cloud-synced folder.
r = system.file(package="psidR")

f = fread(file.path(r,"psid-lists","famvars_big.txt"))
i = fread(file.path(r,"psid-lists","indvars.txt"))


# next, bring into required shape:

setkey(i,"name")
setkey(f,"name")
i = dcast(i[,list(year,name,variable)],year~name, value.var = "variable")
f = dcast(f[,list(year,name,variable)],year~name, value.var = "variable")
d = build.panel(datadir="C:/psid_temp/psid_new",fam.vars=f,
                ind.vars=i, 
                heads.only =TRUE,sample="SRC",
                design="all")

save(d,file="psid.RData")
write.dta(d,"psid.dta")

# alternatively, use `getNamesPSID`:
cwf <- read.xlsx("Downloads/psid.xlsx")
head_age_var_name <- getNamesPSID("ER48848", cwf, years=c(2003,2005,2007,2009,2011,2013))
head_age_var_name
