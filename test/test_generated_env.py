import subprocess
import os
import yaml

def run_bash_script(yamlFlowFile):
    try:
        print(f"Path to file to be processed: {yamlFlowFile}")

        bash_script_path = os.path.abspath("scripts/export-jobs.sh")
        print(f"Path to bash script: {bash_script_path}")

        # Variables representing the bash script and its arguments
        bash_script_name = bash_script_path
        bash_script_argument = yamlFlowFile

        # Command to be executed
        command = ["bash", bash_script_name, bash_script_argument]

        result = subprocess.check_output(command, text=True, stderr=subprocess.STDOUT)
        print(f"Result: {result}")
        return result.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e}")

def check_env_variables(content, expected):

    # Split the content into lines
    lines = content.splitlines()

    for line in lines:
        # Check if the line starts with "export"
        if line.strip().startswith("export "):
            # Get the content following "export"
            enVarStr = line.strip()[7:]

            assert enVarStr in expected, print(f"{enVarStr} is not present in the array.")

def test_generated_env():

    # Process using the bash script the YAML GitHub Workflow file and get the content generated
    path_file_to_process = os.path.abspath("samples/simple-flow.yml")
    generated_content = run_bash_script(path_file_to_process)

    # Define the expected key-value pairs
    expected = """
    GITHUB_TOKEN=\x1b[0;33m<CHANGE_ME: secrets.GITHUB_TOKEN >\x1b[0m'
    FIRST_NAME=Mona
    LAST_NAME=Lisa
    """

    check_env_variables(generated_content, expected)

    # If all tests pass, the environment variables are valid
    print("All tests passed. Environment variables generated are valid.")