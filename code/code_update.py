import typer
from jinja2 import Template, Environment, FileSystemLoader

def run(api_endpoint_dns_name: str = ""):

    template_path = './code/templates'
    output_path = './code/'
    templates = ['streamlit_app.py.tmpl']

    loader = FileSystemLoader(template_path)
    env = Environment(loader=loader) #, variable_start_string='@@=', variable_end_string='=@@')

    for template_file_name in templates:

        template = env.get_template(template_file_name)
        final_file_name = template_file_name[0:template_file_name.rindex('.')]
        output_from_parsed_template = template.render(api_endpoint_dns_name=api_endpoint_dns_name)

        with open(output_path + final_file_name, "w") as fh:
            fh.write(output_from_parsed_template)

if __name__ == "__main__":
    typer.run(run)