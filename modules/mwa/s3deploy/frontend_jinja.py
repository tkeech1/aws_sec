from jinja2 import Template, Environment

env = Environment(variable_start_string='@@=', variable_end_string='=@@')

with open('modules/mwa/s3deploy/tmp/index.html') as f:
    read_data = f.read()

print(read_data)

template = env.get_template(read_data)
output_from_parsed_template = template.render(cognito_user_pool_id='something')

#template = Template('Hello {{ name }}!')
#output_from_parsed_template=template.render(name='John Doe')

#print (output_from_parsed_template)

with open("modules/mwa/s3deploy/tmp/my_new_file.html", "w") as fh:
    fh.write(output_from_parsed_template)