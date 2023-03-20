#!/bin/bash
echo "GoM survey analaysis - March 2023\n\n"

# Import data
echo "importing data"

qiime tools import \
        --type 'SampleData[PairedEndSequencesWithQuality]' \
	--input-path /scratch/user/skhu/gom-hrr/manifest.tsv \
        --output-path gom.qza \
        --input-format PairedEndFastqManifestPhred33V2

# Get starting stats on input sequences
qiime demux summarize \
        --i-data gom-pe.qza \
        --o-visualization gom-pe.qzv

# Remove 18S V4 primers
echo "run cutadapt"

qiime cutadapt trim-paired \
        --i-demultiplexed-sequences gom-pe.qza \
        --p-cores 4 \
        --p-front-f CCAGCASCYGCGGTAATTCC \
        --p-front-r ACTTTCGTTCTTGAT \
        --p-error-rate 0.1 \
        --p-overlap 3 \
       --p-match-adapter-wildcards \
        --o-trimmed-sequences gom-pe-trimmed.qza 

# Grab trim stats from cutadapt
qiime demux summarize \
        --i-data gom-pe-trimmed.qza \
        --o-visualization gom-pe-trimmed.qzv

# Run dada2
echo "executing dada2"
echo "threads queued" $OMP_NUM_THREADS

qiime dada2 denoise-paired \
        --i-demultiplexed-seqs gom-pe-trimmed.qza \
        --p-trunc-len-f 215 \
        --p-trunc-len-r 200 \
        --p-max-ee-f 2 \
        --p-max-ee-r 2 \
        --p-min-overlap 10 \
        --p-pooling-method independent \
        --p-n-reads-learn 100000 \
        --p-n-threads $OMP_NUM_THREADS \
        --p-chimera-method pooled \
        --o-table /scratch/user/skhu/gom-hrr/gom-asv-table.qza \
        --o-representative-sequences /scratch/user/skhu/gom-hrr/gom-ref-seqs.qza \
        --o-denoising-stats /scratch/user/skhu/gom-hrr/gom-dada2-stats.qza

# Get dada2 stats
echo "dada2 stats"

qiime metadata tabulate \
  --m-input-file /scratch/user/skhu/gom-hrr/gom-dada2-stats.qza \
  --o-visualization gom-dada2-stats-summ.qzv


## Convert to TSV ASV table
echo "converting to TSV table"
qiime tools export \
        --input-path /scratch/user/skhu/gom-hrr/gom-asv-table.qza \
	--output-path /scratch/user/skhu/gom-hrr/gom-output/
        
biom convert -i /scratch/user/skhu/gom-hrr/gom-output/feature-table.biom \
       -o /scratch/user/skhu/gom-hrr/gom-output/gom-asv-table.tsv \
       --to-tsv

# Get dada2 stats
qiime metadata tabulate \
       --m-input-file /scratch/user/skhu/gom-hrr/gom-dada2-stats.qza \
       --o-visualization /scratch/user/skhu/gom-hrr/gom-dada2-stats.qzv

# Assign taxonomy
echo "assigning taxonomy, vsearch"
echo "threads queued" $OMP_NUM_THREADS

qiime feature-classifier classify-consensus-vsearch \
        --i-query /scratch/user/skhu/gom-hrr/gom-ref-seqs.qza \
        --i-reference-reads /home/skhu/db/pr2_version_4.14_seqs.qza \
        --i-reference-taxonomy /home/skhu/db/pr2_version_4.14_tax.qza  \
        --o-classification /scratch/user/skhu/gom-hrr/gom-taxa.qza \
        --o-search-results /scratch/user/skhu/gom-hrr/gom-blast6.qza \
        --p-threads $OMP_NUM_THREADS \
        --p-maxaccepts 10 \
        --p-perc-identity 0.8 \
        --p-min-consensus 0.70
# Export taxonomy table
echo "final export taxonomy table step"

qiime tools export \
        --input-path /scratch/user/skhu/gom-hrr/gom-taxa.qza \
        --output-path /scratch/user/skhu/gom-hrr
