import os
import shutil
#set_workflow
#workdir: "/gpfs/hpc/home/lijc/zhuzp/PTpipe"
def convert_config(dict_obj, top=None, key_chain_list=[]):
  """自动替换字典中的模板字符串"""

  if top is None:
    top = dict_obj # top 保存原始的 config 文件

  for key, value in dict_obj.items():
    _key_chain_list = key_chain_list.copy() # 使用复制的列表进行后续处理，保证原列表由于引用传递不被修改

    if isinstance(value, dict):
      _key_chain_list.append(key)
      convert_config(value, top, _key_chain_list)

    if isinstance(value, str):
      # print('======= keys: ', key_chain_list, key)      # === DEBUG ===
      # print('old value: ', value)                       # === DEBUG ===
      tmpls = re.findall(r'\$\{[\.\w-]+?\}', value)
      for tmpl in tmpls:
        keys = tmpl[2:-1].split(".")
        val = top
        for k in keys:
          val = val[k]
        if not isinstance(val, str):
          print(f"(convert_config) Warning: The type of '{tmpl.strip('${} ')}' is not str, but will be forced to the str!")
          val = str(val)
        value = value.replace(tmpl, val)
      # print('new value: ', value)                       # === DEBUG ===

      update_dict = top # 用于 top 的更新
      for k in key_chain_list:
        update_dict = update_dict[k]
      # print('------- before：', '\n', top)              # === DEBUG ===
      update_dict[key] = value # 替换更新
      # print('------- after：', '\n', top)               # === DEBUG ===

    # TODO int, float, list, ...

configfile: "config/config.yaml"
convert_config(config)

#创建软链接的函数
def create_symlink(src, dst):
    if not os.path.exists(dst):
        os.symlink(src, dst)

def copy_or_symlink(src, dst):
    """
    如果 src 是文件，则创建符号链接到 dst。
    如果 src 是符号链接，则复制符号链接指向的文件到 dst。
    """
    if not os.path.exists(dst):
        if os.path.islink(src):
            # 如果 src 是符号链接，则先找到其对应的真实文件，在创建软链接
            real_path = os.readlink(src)
            os.symlink(real_path, dst)
            #shutil.copyfile(real_path, dst)
        elif os.path.isfile(src):
            # 如果 src 是文件，则创建软链接
            os.symlink(src, dst)

if not config["base"]["baseqc"]["value"]:
    create_symlink(config["base"]["input"]["value"], "data/01_qc1.vcf.gz")
    create_symlink(config["base"]["input"]["value"], "data/02_qc2.vcf.gz")
    create_symlink(config["base"]["input"]["value"], "data/02_qc2.vcf")
    create_symlink(config["base"]["input"]["value"], "data/02_qc2.irem")
    create_symlink(config["base"]["input"]["value"], "data/02_qc2.nosex")
    create_symlink(config["base"]["input"]["value"], "data/02_qc2.log")

if not config["base"]["sample_sel"]["value"]:
    copy_or_symlink("data/02_qc2.vcf.gz", "data/03_SamSel.vcf.gz")

def tools_param_parse(param_dict):
	param_str = list()
	for k,v in param_dict.items():
		if v is True:
			param_str.append(f'{k}')
		elif v is False:
			continue
		elif isinstance(v, list):
			value_list = [f'{k} "{p}"' for p in v]
			param_str += value_list
		else:
			param_str.append(f'{k} "{v}"')

	param_str = ' '.join(param_str)
	return param_str


rule all:
    input:
         config["base"]["output"]["value"]







# Different modules
include: "workflow/rules/baseQC.smk"
include: "workflow/rules/SamSel.smk"
include: "workflow/rules/MutSel.smk"
include: "workflow/rules/VCNum.smk"





