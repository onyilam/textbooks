library(data.table)
library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)
library(tidytext)
library(stm)
library(quanteda)
library(tm)
library(jiebaR)
library(fastDummies)
library(igraph)

#convert the docs into smaller unit 

setwd("/Users/onyilam/Dropbox/HistoryTextbook/")

corpus <- data.frame(V1=character(), 
                     origin = character(),
                 stringsAsFactors=FALSE) 

for (val in c('^tw_', '^ma_', '^hk_')) {

  txt_files <- list.files(path = "/Users/onyilam/Dropbox/history_textbooks_txt", recursive = FALSE,
                              pattern = sprintf("%s", val), 
                              full.names = TRUE)
  
  for (f in txt_files) {
    giantStr <- readChar(f, file.info(f)$size ) 
    giantStr <- gsub("\n", "", giantStr) 
    giantStr <- gsub("\t", "", giantStr) 
    giantStr <- gsub("\r", "", giantStr) 
    # separate str into sentences by punctuation.
    indivStr <- str_split(giantStr, '。|？|:', n = Inf, simplify = FALSE)
    # convert data type into dataframe
    df <- data.frame(matrix(unlist(indivStr), nrow=length(indivStr), byrow=T) , stringsAsFactors=FALSE)
    df <- data.frame(t(df))
    loc <- gsub("[^a-zA-Z]", "", val)
    df$origin <- loc
    corpus <-rbind(df, corpus)
    
  }
}
# rename column
names(corpus)[names(corpus) == "t.df."] <- "sentence"
# remove empty rows
corpus <- corpus[!apply(corpus == "", 1, any),]
corpus <- corpus[!apply(corpus == "\n", 1, any),]
corpus <- corpus[!apply(corpus == "\r", 1, any),]
corpus <- corpus[!apply(corpus == "\t", 1, any),]
# dummify the origin variable
corpus <- fastDummies::dummy_cols(corpus, select_columns = "origin")


worker = worker()
corpus$segmented <- apply(corpus, 1, function(x) segment(x, worker))
corpus$segmented = lapply(corpus$segmented, function(x) paste(x, collapse= " "))


processed <- textProcessor(corpus$segmented, metadata=corpus)
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh=2, upper.thresh=7000)
stm <- stm(documents=out$documents, K=8, vocab=out$vocab, data=out$meta, 
                prevalence=~origin_ma + origin_tw, seed=234, init.type = "Spectral", max.em.its = 50)

# results
labelTopics(stm)

# plot topic
plot.STM(stm,type="summary")


#estimate the region effect
prep <- estimateEffect(1:8~ origin_ma + origin_tw
                      , stm, meta=out$meta, uncertainty="Global")
summary(prep)

plot(prep, 'origin_ma', verbose.labels = T, method = "continuous")
plot(prep, 'origin_tw', verbose.labels = T, method = "continuous")


corr = topicCorr(stm)
plot(corr) 

# example sentences that fit into the topic
cc <- corpus[-c(processed$docs.removed),]
cc <- cc[-c(out$docs.removed),]
findThoughts(stm, cc$segmented, topics=1, meta=out$meta)


# check how number of topics change the number of significant topics.

res <- vector("list", 11)
for (num in 5:15){
  stm <- stm(documents=out$documents, K=num, vocab=out$vocab, data=out$meta, 
             prevalence=~origin_ma + origin_tw, seed=234, init.type = "Spectral", max.em.its = 50)
  
  #estimate effect
  prep <- estimateEffect(~origin_ma + origin_tw, stm, meta=out$meta, uncertainty="Global")
  res[[num]]<-summary(prep)
}



