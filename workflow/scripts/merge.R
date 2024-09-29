library(data.table)

args <- commandArgs(trailingOnly=TRUE)
hwe_input <- args[1]
bim_input <- args[2]
output <- args[3]

hwe <- fread(hwe_input, sep = " ",header = T,nThread =36)
bim <- fread(bim_input, sep = "\t",header = F,nThread =36)
if(all(hwe$A1 == bim$V5)){
    a=bim[,c(1,4:6)]
    b=cbind(a,hwe[,6])
  }
bb <- cbind(b[,c(1:2)],b[,4],b[,3],b[,5])
carriers=strsplit(bb$GENO, "/")
bb = bb[,-5]
cc <- cbind(bb, do.call(rbind, carriers))
colnames(cc)=c("CHR","POS","REF","ALT","Carriers_hom","Carriers_het","Total_num")
#trans_to_annovar
cc = as.matrix(cc)
end=c(1:nrow(cc))
data = cc
for(i in 1:nrow(data)){
  end[i]=as.numeric(data[i,2])+nchar(data[i,3])-1
}
data1=as.matrix(cbind(data[,1:2], end, data[,3:ncol(data)]))
colnames(data1)[2:3]=c("START","END")
##process_ref_alt
for (i in 1:nrow(data1)) {
  if (nchar(data1[i,4]) > 1 & nchar(data1[i,5]) == 1) {
    data1[i,5] <- "-"
    data1[i,4] <- substr(data1[i,4], 2, nchar(data1[i,4]))
    data1[i,2] <- as.numeric(data1[i,2]) + 1
  } else if(nchar(data1[i,4]) == 1 & nchar(data1[i,5]) > 1 ) {
    data1[i,4] <- "-"
    data1[i,5] <- substr(data1[i,5], 2, nchar(data1[i,5]))
  }
}
data1 = as.data.frame(data1)



#output
fwrite(data1,output,quote = FALSE,row.names = FALSE,sep = "\t")

