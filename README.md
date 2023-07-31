<p align="center">
    <a href="https://github.com/ch007m/export-github-flows/graphs/contributors" alt="Contributors">
        <img src="https://img.shields.io/github/contributors/ch007m/export-github-flows"/></a>
    <a href="https://github.com/ch007m/export-github-flows/pulse" alt="Activity">
        <img src="https://img.shields.io/github/commit-activity/m/ch007m/export-github-flows"/></a>
</p>

# Export github workflows

This project aims to read [github workflows](https://docs.github.com/en/actions/quickstart) and to export in a txt file the `env` and `run` sections.

Why ? As the goal of a 2e2 test, played by a GitHub workflow, is to verify if the scenario which requires to potentially install many
components on the platform (kubernetes cluster, certificate manager, tekton pipeline, service binding, vault, crossplane etc) 
works, the information such as `run:` or `run: |`  or environment variables set `env:` could be more than valuable
for local debugging, fine-tuning, etc purposes.

So, to export the information in a file, you can then use the following bash script and pass as parameter the file to be processed:
```bash
./scripts/export-jobs.sh </path/workflow-file.yml>
```
The script will then read the file and export the environment variables and each `run` block

Example of flow:
```yaml
name: gitHub Workflow sample

on:
  push:
    branches: [ main ]
    paths-ignore:
      - '*.md'          # Ignores .md files at the root of the repository
      - '**/*.md'       # Ignores .md files within subdirectories

env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  job1:
    env:
      FIRST_NAME: Mona
      LAST_NAME: Lisa

    steps:
      - name: Install Dependencies
        run: npm install

      - name: Clean install dependencies and build
        run: |
          npm ci
          npm run build

      - name: Clean temp directory
        run: rm -rf *
        working-directory: ./temp
```

And what we got:

<img src="https://github.com/ch007m/export-github-flows/blob/main/images/sample-flow.png" width="700"/>


**Important**: Some hacking will be needed as the script cannot figure out what the [GitHub default variables](https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables) are 
and cannot perform substitution too. 

Example:
```yaml
GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
Generated into:

<img src="https://github.com/ch007m/export-github-flows/blob/main/images/sample-git-env.png" width="500"/>