rule all:
    input:
        "variants.vcf"

rule copy_data:
    output: "SRR2584857_1.n100000.fq"
    shell:
        "ln -s ~/298class5/yeast/SRR2584857_1.n100000.fq ."

rule download_genome:
    output:
        "ecoli-rel606.fa.gz"
    shell:
        "wget https://osf.io/8sm92/download -O {output}"

rule uncompress_genome:
    input: "ecoli-rel606.fa.gz"
    output: "ecoli-rel606.fa"
    shell:
        "gunzip {input}"

rule index_genome_bwa:
    input: "ecoli-rel606.fa"
    output:
        "ecoli-rel606.fa.amb",
        "ecoli-rel606.fa.ann",
        "ecoli-rel606.fa.bwt",
        "ecoli-rel606.fa.pac",
        "ecoli-rel606.fa.sa"
    shell:
        "bwa index {input}"

rule map_reads:
    input:
        ref='ecoli-rel606.fa',
        z='ecoli-rel606.fa.amb',
        sample='SRR2584857_1.n100000.fq'
    output:
        "SRR2584857_1.n100000.sam"
    shell:
        "bwa mem -t 4 {input.ref} {input.sample} > {output}"

rule index_genome_samtools:
    input:
        "ecoli-rel606.fa"
    output:
        "ecoli-rel606.fa.fai"
    shell:
        "samtools faidx {input}"
        
rule samtools_import:
    input:
        gen='ecoli-rel606.fa.fai',
        sample='SRR2584857_1.n100000.sam'
    output:
        "SRR2584857_1.n100000.bam"
    shell:
        "samtools import {input.gen} {input.sample} {output}"

rule samtools_sort:
    input:
        "SRR2584857_1.n100000.bam"
    output:
        "SRR2584857_1.n100000.sorted.bam"
    shell:
        "samtools sort {input} -o {output}"

rule samtools_index_sorted:
    input: "SRR2584857_1.n100000.sorted.bam"
    output: "SRR2584857_1.n100000.sorted.bam.bai"
    shell: "samtools index {input}"

rule samtools_mpileup:
    input:
        ref='ecoli-rel606.fa',
        sample='SRR2584857_1.n100000.sorted.bam'
    output: "variants.raw.bcf"
    shell:
        """samtools mpileup -u -t DP -f {input.ref} {input.sample} | \
        bcftools call -mv -Ob -o - > {output}"""

rule make_vcf:
    input: "variants.raw.bcf"
    output: "variants.vcf"
    shell: "bcftools view {input} > {output}"
