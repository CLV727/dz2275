library(qiime2R)
library(phyloseq)
library(MicrobeR) # Data visualization
library(microbiome) # Data analysis and visualization
library(plyr)

rm(list = ls())
setwd("C:/Users/dingw/OneDrive/Desktop/mydata")
group1<-read.delim('metadata.txt',header = T)
colnames(group1)

phy <- qza_to_phyloseq(
  features = "table.qza", 
  tree = "rooted-tree.qza", 
  taxonomy = "taxonomy.qza", 
  metadata = "metadata.txt"
)
phy

# check for features of data  
summarize_phyloseq(phy)
theme_set(theme_bw())
GP = phy
temp<-filterfun_sample
wh0 = genefilter_sample(GP, filterfun_sample(function(x) x > 5), A=0.5*nsamples(GP))
GP1 = prune_taxa(wh0, GP)
myotu<-otu_table(GP1)
myout2<-myotu@.Data
write.table(cbind(Id=rownames(myout2),myout2),'filter_otu.xls',row.names = F,sep = '\t',quote = F)

GP1 = transform_sample_counts(GP1, function(x) 1E6 * x/sum(x))

myotu<-otu_table(GP1)
myout2<-myotu@.Data
write.table(cbind(Id=rownames(myout2),myout2),'percent_filter_otu.xls',row.names = F,sep = '\t',quote = F)


phylum.sum = tapply(taxa_sums(GP1), tax_table(GP1)[, "Phylum"], sum, na.rm=TRUE)
top5phyla = names(sort(phylum.sum, TRUE))[1:5]
GP1 = prune_taxa((tax_table(GP1)[, "Phylum"] %in% top5phyla), GP1)
colnames(group1)


GP.ord <- ordinate(GP1, "NMDS", "bray")
p1 = plot_ordination(GP1, GP.ord, type="taxa", color="Phylum", title="taxa")
print(p1)

p1 + facet_wrap(~Phylum, 3)

p2 = plot_ordination(GP1, GP.ord, type="samples", 
                     color="group", shape="group") 

p2 + geom_polygon(aes(fill=group)) + geom_point(size=1) + ggtitle("samples")


p3 = plot_ordination(GP1, GP.ord, type="biplot", color="group", shape="Phylum", title="biplot")
p3
# Some stuff to modify the automatic shape scale
GP1.shape.names = get_taxa_unique(GP1, "Phylum")
GP1.shape <- 15:(15 + length(GP1.shape.names) - 1)
names(GP1.shape) <- GP1.shape.names
GP1.shape["samples"] <- 16
p3 + scale_shape_manual(values=GP1.shape)

p4 = plot_ordination(GP1, GP.ord, type="split", color="Phylum", shape="group",
                     label="group", title="split") 
p4

gg_color_hue <- function(n){
  hues = seq(15, 375, length=n+1)
  hcl(h=hues, l=65, c=100)[1:n]
}
color.names <- levels(p4$data$Phylum)
p4cols <- gg_color_hue(length(color.names))
names(p4cols) <- color.names
p4cols["samples"] <- "black"
p4 + scale_color_manual(values=p4cols)


dist = "bray"
ord_meths = c("DCA", "CCA", "RDA", "DPCoA", "NMDS", "MDS", "PCoA")


plist = llply(as.list(ord_meths), function(i, physeq, dist){
  ordi = ordinate(physeq, method=i, distance=dist)
  plot_ordination(physeq, ordi, "samples", color="group")
}, GP1, dist)

names(plist) <- ord_meths


pdataframe = ldply(plist, function(x){
  df = x$data[, 1:2]
  colnames(df) = c("Axis_1", "Axis_2")
  return(cbind(df, x$data))
})

names(pdataframe)[1] = "method"

p = ggplot(pdataframe, aes(Axis_1, Axis_2, color=group, shape=group, fill=group))
p = p + geom_point(size=4) + geom_polygon()
p = p + facet_wrap(~method, scales="free")
p = p + scale_fill_brewer(type="qual", palette="Set1")
p = p + scale_colour_brewer(type="qual", palette="Set1")
p

plist[[2]] 



p = plist[[2]] + scale_colour_brewer(type="qual", palette="Set1")
p = p + scale_fill_brewer(type="qual", palette="Set1")
p = p + geom_point(size=5) + geom_polygon(aes(fill=group))
p

ordu = ordinate(GP1, "PCoA", "unifrac", weighted=TRUE)
plot_ordination(GP1, ordu, color="group", shape="group")


p = plot_ordination(GP1, ordu, color="group", shape="group")
p = p + geom_point(size=7, alpha=0.75)
p = p + scale_colour_brewer(type="qual", palette="Set1")
p + ggtitle("MDS/PCoA on weighted-UniFrac distance, GlobalPatterns")


