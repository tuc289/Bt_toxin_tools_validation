## Calculating SP, SN, PPV, NPV
table <- read.csv("~/Downloads/Four_Methods_Results_NP_P.csv", 
                  row.names=1, header=T)

for(i in 2:ncol(table)) {
  name <- paste(colnames(table[i]))
  eval(call("<-", as.name(name), table[,c(1,i)]))
  print(colnames(table[i]))
} ## Creating multiple object with one treatment against standard

SNSPPVs <- function(input_matrix){
  input = input_matrix
  
  for(i in 1:nrow(input)){
    if(input[i,1] == 1 & input[i,2] == 1){
      input[i,3] = "TP" 
    } else if(input[i,1] == 1 & input[i,2] == 0){
      input[i,3] = "FN"
    } else if(input[i,1] == 0 & input[i,2] == 1){
      input[i,3] = "FP"
    } else if(input[i,1] == 0 & input[i,2] == 0){
      input[i,3] = "TN"
    } else {input[i,3] <- "NA"}
  }
  colnames(input)[3] = "Result"
  
  matrix <- as.data.frame(table(input[3]))
  if(length(matrix$Result[matrix$Result == "FP"]) ==0){
    matrix <- rbind(matrix, data.frame(Result="FP", Freq =0))
  }
  if(length(matrix$Result[matrix$Result == "TP"]) ==0){
    matrix <- rbind(matrix, data.frame(Result="TP", Freq =0))
  }
  if(length(matrix$Result[matrix$Result == "FN"]) ==0){
    matrix <- rbind(matrix, data.frame(Result="FN", Freq =0))
  }
  if(length(matrix$Result[matrix$Result == "TN"]) ==0){
    matrix <- rbind(matrix, data.frame(Result="TN", Freq =0))
  }
  
  
  a = matrix$Freq[matrix$Result == "TP"] #True positive (TP)
  b = matrix$Freq[matrix$Result == "FP"] #False positive (FP)
  c = matrix$Freq[matrix$Result == "FN"] #False negative (FN)
  d = matrix$Freq[matrix$Result == "TN"] #True negative (TN)
  
  
  result <- data.frame(matrix(ncol=4, nrow=1))
  colnames(result) <- c("SN", "SP", "PPV", "NPV")
  result[1,1] <- a/(a+c)
  result[1,2] <- b/(b+d)
  result[1,3] <- a/(a+b)
  result[1,4] <- d/(c+d)
  list <- list()
  list[[1]] <- result
  list[[2]] <- matrix
  list[[3]] <- deparse(substitute(input_matrix))
  names(list) <- c("Result", "Matrix", "Name")
  return(list)
} #Making functions to calculate SN, SP, PPV, NPV

#parse result
parse_SNSPPPVs <- function(table){
  final_result <- data.frame(matrix(nrow=ncol(table)-1, ncol=4))
  colnames(final_result) <- c("SN", "SP", "PPV", "NPV")
  for(i in colnames(table)[2:ncol(table)]){
    tool <- get(i)
    calculation <- SNSPPVs(tool)
    calculation$Name <- i
    eval(call("<-", paste("calculation", i, sep="_"), calculation))
  }
  
  for(i in 2:ncol(table)){
    final_result[i-1,] <- get(paste("calculation", colnames(table[i]), sep="_"))$Result[1,]
    rownames(final_result)[i-1] <- colnames(table[i])
  }
  return(final_result)
}

final_result <- parse_SNSPPPVs(table)
final_result
