rule SamSel:
    input:
        sample = config["base"]["samplelist"]["value"],
        vcf = "data/02_qc2.vcf.gz"
    output:
        "data/03_SamSel.vcf.gz"
    log:
        "logs/SamSel.log"
    threads: config["base"]["threads"]["value"]
    shell:
        """
        bcftools view -S {input.sample} {input.vcf} -Oz --threads {threads} -o {output} 2> {log}
        """
