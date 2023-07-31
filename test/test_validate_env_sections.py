import os
import yaml

def read_yaml_file(filename):
    with open(filename, 'r') as file:
        yaml_data = yaml.safe_load(file)
    return yaml_data

def get_env_nodes(yaml_data):
    env_nodes = []
    def find_env_nodes(node):
        if isinstance(node, dict):
            if 'env' in node:
                env_nodes.append(node['env'])
            for key, value in node.items():
                find_env_nodes(value)
        elif isinstance(node, list):
            for item in node:
                find_env_nodes(item)

    find_env_nodes(yaml_data)
    return env_nodes

def group_env(env_nodes):
    grouped_env = {}
    for env in env_nodes:
        for key, value in env.items():
            if key in grouped_env:
                grouped_env[key].append(value)
            else:
                grouped_env[key] = value
    return grouped_env

def test_env_section():

    # Get the YAML file path from command-line argument
    current_directory = os.getcwd()
    yaml_file_path = f"{current_directory}/samples/simple-flow.yml"

    print("Path of the file:", yaml_file_path)
    yaml_data = read_yaml_file(yaml_file_path)

    env_nodes = get_env_nodes(yaml_data)
    grouped_env = group_env(env_nodes)

    # Define the expected key-value pairs for each test case
    expected = {
        "GITHUB_TOKEN": "${{ secrets.GITHUB_TOKEN }}",
        "FIRST_NAME": "Mona",
        "LAST_NAME": "Lisa",
    }

    # Iterate through the test cases
    for key, value in expected.items():
        # Check if the key exists in 'group_env'
        assert key in grouped_env, f"Key '{key}' not found in group_env"

        # Check if the value of the key matches the expected value
        assert grouped_env[key] == value, f"Value for key '{key}' does not match expected value"

    # If all tests pass, the environment variables are valid
    print("All tests passed. Environment variables are valid.")