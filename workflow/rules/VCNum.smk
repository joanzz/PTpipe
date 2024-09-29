rule final_cal:
    input:
        rules.VCF_sorted.output
    output:
        config["base"]["output"]["value"]
    log:
        "logs/final_cal.log"
    threads: config["base"]["threads"]["value"]
    shell:
        """
        paste <(bcftools view {input} | awk -F"\t" 'BEGIN {{print "CHR\tPOS\tID\tREF\tALT"}} !/^#/ {{print $1"\t"$2"\t"$3"\t"$4"\t"$5}}') \
              <(bcftools query -f '[\t%SAMPLE=%GT]\n' {input} | awk 'BEGIN {{print "nHet\tHom"}} {{het_count=gsub(/0\\|1|1\\|0|0\\/1|1\\/0/, ""); hom_count=gsub(/1\\|1|1\\/1/, ""); print het_count"\t"hom_count}}') \
              > {output} 2> {log}
        """
