rule variantQC:
    input:
        vcf = config["base"]["input"]["value"],
        ref = "data/reference/hg38.fa"
    output:
        "data/01_qc1.vcf.gz"
    log:
        "logs/variantQC.log"
    threads: config["base"]["threads"]["value"]
    params:
        include = config['tools']['bcftools_include']['params'],
        exclude = config['tools']['bcftools_exclude']['params']
    shell:
        """
        bcftools norm -f {input.ref} -m -any {input.vcf} | bcftools filter -e {params.exclude} | bcftools view -i {params.include} --threads {threads} -Oz -o {output} 2> {log}
        """

rule sampleQC:
    input:
        rules.variantQC.output
    output:
        expand("data/02_qc2.{suffix}", suffix=["irem", "log","nosex","vcf","vcf.gz"])
    log:
        "logs/sampleQC.log"
    threads: config["base"]["threads"]["value"]
    params:
        tools_param_parse(config['tools']['plink_qc']['params'])
    shell:
        """
        plink --vcf {input} --allow-extra-chr 0 --vcf-half-call m {params} --recode vcf --out data/02_qc2 2> {log}
        bgzip -c data/02_qc2.vcf > data/02_qc2.vcf.gz 2>> {log}
        """




