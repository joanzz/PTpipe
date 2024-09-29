rule VCF_sorted:
    input:
        rules.SamSel.output
    output:
        "data/04_sorted.vcf.gz"
    log:
        "logs/VCF_sorted.log"
    threads: config["base"]["threads"]["value"]
    shell:
        """
	bcftools sort {input} -T data/ -Oz -o {output} 2> {log}
	tabix -p vcf {output}  2>> {log}
	    """
