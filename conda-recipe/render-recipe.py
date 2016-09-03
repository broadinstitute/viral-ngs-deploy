#!/usr/bin/python

import os
import glob
import jinja2

"""
Renders Jinja2 templates stored in an input directory at the same level as this
script. Output files are written to an output directory at the same level.

The behavior is not recursive.
"""

input_directory = "viral-ngs-template"
output_directory = "viral-ngs"

dir_path = os.path.dirname(os.path.realpath(__file__))

if __name__ == "__main__":
    from jinja2 import Environment, FileSystemLoader
    j_env = Environment(loader=FileSystemLoader(input_directory))

    if not os.path.exists(output_directory):
        os.makedirs(output_directory)


    print(os.path.join(dir_path,input_directory)+"/*")
    #template_files = glob.glob( os.path.join(dir_path, input_directory)+"/*" )
    template_files = os.listdir(input_directory)
    print(template_files)

    for template_file in template_files:
        template = j_env.get_template(template_file)
        output_from_parsed_template = template.render(os.environ)
        print(output_from_parsed_template)

        # save the rendered output
        with open(os.path.join(output_directory, template_file), "wb") as f:
            f.write(output_from_parsed_template)