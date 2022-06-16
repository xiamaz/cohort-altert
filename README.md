# varlert

Joint filtration and summarization of interesting variants.

## Setup

Obtain GFF3 Data from Ensembl using the following command:

```
$ rsync -av rsync://ftp.ensembl.org/ensembl/pub/grch37/release-106/gff3/homo_sapiens data/

receiving incremental file list
homo_sapiens/
homo_sapiens/CHECKSUMS
homo_sapiens/Homo_sapiens.GRCh37.87.abinitio.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chr.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chr_patch_hapl_scaff.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chromosome.1.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chromosome.10.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chromosome.11.gff3.gz
homo_sapiens/Homo_sapiens.GRCh37.87.chromosome.12.gff3.gz
...
```
