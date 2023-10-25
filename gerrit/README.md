## Gerrit Docker image

This project defines the Docker image to be used with the AWS recipes, as described in the main
[README](../README.md).

### Generate Python requirements file

Occasionally we need to update the Python dependencies. These could be due to upgrading the base
image, or just to upgrade the libraries.

Follow these steps to generate a new requirements file for reproducible builds.

```bash
# This needs to match the base image of the Gerrit build
docker run -it almalinux:9 bash
yum install python3 python3-libs python3-devel python3-pip

cd
python3 -m venv venv

source venv/bin/activate

# These are our direct dependencies
pip install boto3==1.23.10 jinja2==2.11.1 awscli==1.24.10

# Required for compatibility with the pinned version of jinja2
pip install markupsafe==2.0.1

pip freeze > requirements.in

python3 -m pip install pip-tools
pip-compile --generate-hashes requirements.in
```
