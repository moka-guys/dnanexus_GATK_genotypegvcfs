# dnanexus_gatk_genotypevcfs
[broadinstute/gatk:4.0.9.0](https://hub.docker.com/r/broadinstitute/gatk/)

## What does this app do?
This application takes a set of input variant call files in Genomic VCF (GVCF) format and returns a combined multi-sample VCF. This is the output of the GATK joint genotyping workflow, which makes genotype calls accross samples.

The application generates the raw SNP and INDEL calls using [GenomicsDBImport](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.9.0/org_broadinstitute_hellbender_tools_genomicsdb_GenomicsDBImport.php) and [GenotypeVCFs](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.9.0/org_broadinstitute_hellbender_tools_walkers_GenotypeGVCFs.php).

Utilising information accross samples, variants called through this workflow have a clearer distinction between homozygous reference sites and sites with missing data, greater sensitivity for low-frequency variants and an improved ability to filter out false-pasitive calls.

## What are typical use cases for this app?
This app is designed to be called on output files from GATK HaplotypeCaller as part of a joint genotyping workflow. 

## What inputs are required for this app to run?
- Input GVCF files (`*.g.vcf`). GVCF files and their indexes are produced by the GATK haplotypecaller using its '-ERC GVCF' flag.
- Input GVCF file indexes (`*.g.vcf.idx`).
- Reference input files for GATK; A fasta file, its index (\*.fai) and its dict file (\*.dict). See [GATK resource bundle](https://software.broadinstitute.org/gatk/download/bundle) for prepared reference files.
- Intervals list - A file (.bed or .list) containing genomic intervals for processing.

Optional arguments are available:
- output_vcf_prefix - A prefix for the output VCF file. The default is to merge the names of the input GVCFs, delimited by an underscore character.
- extra_opts_genomicsdbimport - Additional command-line options to pass to GATK GenomicsDBImport
- extra_optes_genotypegvcfs - Additional command-line optinons to pass to GATK GenotypeGVCFs

## What does this app output?
- A combined VCF file, containing variants for each input sample (`*.vcf`)
- The combined VCF file's index (`*.vcf.idx`)

## How does this app work?
The app downloads the input files and moves all inputs to the home directory (/home/dnanexus). This makes all input files available to gatk as defined by docker. The home directory is mounted to the docker image using the -v flag, which is required to retrieve gatk output files when running through docker.

After setting variables for GATK command strings, the app runs GenomicsDBImport, which aggregates the GVCF files in a local database. This database is passed to GenotypeGVCFs, which generates raw SNP and INDEL calls across all samples as an output VCF.

*Developed by Viapath Genome Informatics*
