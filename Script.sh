#!/bin/bash
# Usage: sh Script.sh forward_read.fastq.gz reverse_read.fastq.gz nanopore_reads.fastq

forward=$1
reverse=$2
long=$3

## 1. Illumina short-read sequencing data processing
## 1.1. Trimming adapters and low-quality reads using Trimmomatic
trimmomatic PE -threads 20 -phred33 $forward $reverse ${forward%.fastq.gz}_1.trimmedP.fastq.gz ${forward%.fastq.gz}_1.trimmedS.fastq.gz ${reverse%.fastq.gz}_2.trimmedP.fastq.gz ${reverse%.fastq.gz}_2.trimmedS.fastq.gz ILLUMINACLIP:/gpfs/group/jzk303/default/data/tuc289/rhAMR/amrplusplus_v2/data/adapters/nextera.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

## 1.2. De-novo assembly using Spades
spades.py -k 99,127 --isolate -1 ${forward%.fastq.gz}_1.trimmedP.fastq.gz -2 ${reverse%.fastq.gz}_2.trimmedP.fastq.gz -o ${forward%.fastq.gz} -t 20 -m 64

## 1.3. Genome assessment using Quast
quast -o ${forward%.fastq.gz}_QUAST ${forward%.fastq.gz}/contigs.fasta

## 1.4. Identifying CDS using prokka
prokka ${forward%.fastq.gz}/contigs.fasta -outdir ${forward%.fastq.gz}_prokka --prefix ${forward%.fastq.gz}

## 2. ONT long-read sequencing data processing
## 2.1. Filtration of low-quality reads
filtlong --min_length 1000 --keep_percent 90 $long | gzip > ${long%.fastq.gz}_filt.fastq.gz

## 2.2. hybrid assembly using Unicycler
unicycler -1 ${forward%.fastq.gz}_1.trimmedP.fastq.gz -2 ${reverse%.fastq.gz}_2.trimmedP.fastq.gz -l ${long%.fastq.gz}_filt.fastq.gz -o ${long%.fastq.gz}_unicycler --mode normal -t 20 --kmers 99,127

## 2.3. Genome assessment using Quast
quast -o ${long%.fastq.gz}_QUAST_hybrid ${long%.fastq.gz}_unicycler/assembly.fasta

## 2.4. Identifying CDS using prokka
prokka ${long%.fastq.gz}/assembly.fasta -outdir ${long%.fastq.gz}_prokka_hybrid --prefix ${long%.fastq.gz}_hybrid

## 3. Bt-toxin detection
## 3.1. BtToxin Digger
BtToxin_Digger --threads 20 --SeqPath ${forward%.fastq.gz}_prokka/${forward%.fastq.gz}.faa --SequenceType prot --Scaf_suffix .faa
BtToxin_Digger --threads 20 --SeqPath ${forward%.fastq.gz}_prokka_hybrid/${long%.fastq.gz}_hybrid.faa --SequenceType prot --Scaf_suffix .faa

## 3.2. IDOPS
idops -o IDOPS_out *_prokka/*.gff
idops -o IDOPS_out_hybrid *_prokka_hybrid/*.gff

## 3.3. cry_processor
cry_processor.py -fi ${forward%.fastq.gz}_prokka/${forward%.fastq.gz}.faa -od ./${forward%.fastq.gz}_do -a -th 20 -r do
cry_processor.py -fi ${forward%.fastq.gz}_prokka/${forward%.fastq.gz}.faa -od ./${forward%.fastq.gz}_fd -a -th 20 -r fd

cry_processor.py -fi ${forward%.fastq.gz}_prokka_hybrid/${forward%.fastq.gz}.faa -od ./${long%.fastq.gz}_hybrid_do -a -th 20 -r do
cry_processor.py -fi ${forward%.fastq.gz}_prokka_hybrid/${forward%.fastq.gz}.faa -od ./${long%.fastq.gz}_hybrid_fd -a -th 20 -r fd

## 3.4. BTyper3
btyper3 -i ${forward%.fastq.gz}/contigs -o ${forward%.fastq.gz}_BTyper3
btyper3 -i ${long%.fastq.gz}_unicycler/assembly.fasta -o ${long%.fastq.gz}_unicycler_BTyper3




