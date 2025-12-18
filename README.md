# Infrastructure as Code: Packer Templates
![Packer Validate](https://github.com/sergey88889999/packer-templates/actions/workflows/validate.yml/badge.svg)
A collection of Packer templates for automatically building "golden images" of virtual machines.

## Requirements

- **Packer** - Ensure the [Packer](https://www.packer.io/downloads) utility is installed on your system.
- **Proxmox VE Access** - Credentials are required to connect to the Proxmox API.

## Configuration

Each template uses a variables file to store private data (credentials, Proxmox URL, etc.).

1.  Navigate to the directory of the desired template (e.g., `debian13-base`).
2.  Copy the example variables file, removing `.example` from the name.
3.  Edit the created `.pkrvars.hcl` file with your details.


## Usage

1. Change to the desired template's directory:
    ```bash
    cd debian13-base
    ```
2. Run the build with the following commands:
    ```bash
    packer init .
    packer validate .
    packer build .
    ```

## Project Structure
### Proxmox
- [debian13-base](./debian13-base/): A base image for Debian 13.02 (Trixie).
- 