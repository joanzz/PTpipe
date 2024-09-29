import argparse
import os
import subprocess
import yaml # type: ignore
import sys
import tempfile
import textwrap

def load_config(config_file):
    with open(config_file, 'r') as file:
        config = yaml.safe_load(file)
    return config

def update_config_with_args(config, args):
    if args.input:
        config['base']['input']['value'] = args.input
    if args.output:
        config['base']['output']['value'] = args.output
    if args.base_qc is not None:
        config['base']['baseqc']['value'] = args.base_qc
    if args.sample_filtering is not None:
        config['base']['sample_sel']['value'] = args.sample_filtering
    if args.threads:
        config['base']['threads']['value'] = args.threads
    if args.samplelist:
        config['base']['samplelist']['value'] = args.samplelist
    if args.cores:
        config['snakemake']['params']['cores']['value'] = args.cores
    if args.use_conda is not None:
        config['snakemake']['params']['use-conda']['value'] = args.use_conda

    if args.plink_qc:
        formatted_params = []
        for param in args.plink_qc:
            split_params = param.split(',')
            for split_param in split_params:
                key, value = split_param.split('=')
                formatted_params.append(f"-{key}: {value}")
        dict_params = {item.split(':')[0]: item.split(':')[1] for item in formatted_params}
        config['tools']['plink_qc']['params']["-geno"] = dict_params['-geno']
        config['tools']['plink_qc']['params']["-hwe"] = dict_params['-hwe']
        config['tools']['plink_qc']['params']["-mind"] = dict_params['-mind']

    if args.bcftools_include:
        config['tools']['bcftools_include']['params'] = args.bcftools_include
    if args.bcftools_exclude:
        config['tools']['bcftools_exclude']['params'] = args.bcftools_exclude

    return config


def parse_arguments():
    parser = argparse.ArgumentParser(description="Run the Snakemake pipeline of PTpipe.",formatter_class=argparse.RawTextHelpFormatter)
    #Create param Group
    base_group = parser.add_argument_group('Base Options')
    snakemake_group = parser.add_argument_group('Snakemake Options')
    tools_group = parser.add_argument_group('Tools Options')
    # Base section arguments
    base_group.add_argument('--input', type=str, help="Path to the input vcf file.")
    base_group.add_argument('--output', type=str, help="Path to the variant carriers file.")
    base_group.add_argument('--base_qc', action='store_true', help="Whether the VCF file needs to be quality controlled.")
    base_group.add_argument('--sample_filtering', action='store_true', help="Whether sample screening is required.If required, use --samplelist to specify the path to the sample list.")
    base_group.add_argument('--samplelist', type=str, help="Path to the sample list.")
    base_group.add_argument('--threads', type=int, default=6, help="Number of threads for pipeline.")
    
    # Snakemake section arguments
    snakemake_group.add_argument('--use_conda', action='store_true', help="Whether to use conda environments.")
    snakemake_group.add_argument('--cores', type=str, default="all",help="Number of cores for Snakemake.")
    
    # Tools section arguments
    tools_group.add_argument('--plink_qc', nargs='*',help= textwrap.dedent('''\
                            Parameters for plink_qc tool in the format 'param=value'.
                            -geno: Genotype missingness rate threshold (Default, 'geno=0.1')
                            -hwe: Hardy-Weinberg equilibrium threshold (Default, 'hwe=1e-15')
                            -mind: Sample missingness rate threshold (Default, 'mind=0.1')
                                                                      '''))

    tools_group.add_argument('--bcftools_include', type=str,help= textwrap.dedent('''\
                            To write filtered expressions according to the rules of bcftools, please refer to the official bcftools documentation for detailed guidelines.
                            The default parameters are for snp, exclude variant sites with depth less than 7, and for Indel, exclude variant sites with depth less than 10.
                                                                      '''))


    tools_group.add_argument('--bcftools_exclude',type=str,help= textwrap.dedent('''\
                            To write filtered expressions according to the rules of bcftools, please refer to the official bcftools documentation for detailed guidelines.
                            The default parameters are to include VAFs that meet SNP ≥ 0.15, Indel ≥ 0.2, or at least one homozygous genotype.
                                                                      '''))
    return parser.parse_args()


def main():
    args = parse_arguments()
    
    if len(sys.argv) == 1:  # No arguments were provided
        print("No arguments provided. Printing help.")
        sys.argv.append('-h')  # Add -h to display help
        parse_arguments()  # Trigger help
        return
    
    config = load_config("config/config.yaml")
    config = update_config_with_args(config, args)

    # 创建临时配置文件
    with tempfile.NamedTemporaryFile('w', delete=False, suffix='.yaml') as temp_config_file:
        yaml.dump(config, temp_config_file)
        temp_config_path = temp_config_file.name
    # 运行 Snakemake
    snakemake_cmd = ["snakemake", "--configfile", temp_config_path, "--cores", args.cores]
    if args.use_conda:
            snakemake_cmd.append("--use-conda")
    try:
        # 运行 Snakemake
        subprocess.run(snakemake_cmd, check=True)
    finally:
        # 删除临时配置文件
        #print(f"配置文件的路径是: {temp_config_path}")
        #with open(temp_config_path, 'r') as file:
            #file_content = file.read()
            #print("配置文件的内容是:")
            #print(file_content)
        #config_file_path = os.path.abspath(config_file)
        os.remove(temp_config_path)
        

if __name__ == "__main__":
    main()
