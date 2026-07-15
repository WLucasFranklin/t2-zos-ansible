# t2-zos-ansible

Automate IBM z/OS lab administration with Ansible.

This repository contains Ansible playbooks, JCL templates, and starter source files for provisioning IBM z/OS user environments. Rather than relying on an existing seed library on the mainframe, the repository stores the files used to initialize each user's development environment, making deployments repeatable and version-controlled.

## Features

- Create RACF users
- Configure TSO and OMVS attributes
- Allocate required data sets
- Upload starter source members from the repository
- Submit initialization JCL
- Fully version-controlled provisioning assets
- Built using the IBM z/OS Core Ansible Collection

## Repository Structure

```
.
├── files/              # Source members copied to new user libraries
├── inventories/        # Inventory files
├── playbooks/          # Ansible playbooks
├── templates/          # JCL templates
├── vars/               # Variables
└── README.md
```

## Provisioning Workflow

A typical provisioning run performs the following steps:

1. Create the RACF user.
2. Configure TSO and OMVS settings.
3. Allocate the required data sets.
4. Copy starter source members from the repository into the user's libraries.
5. Submit initialization JCL.
6. Verify successful provisioning.

## Starter Files

Instead of copying from a pre-existing z/OS seed library, this project stores starter source members directly in the repository.

```
Repository
└── files/
    ├── JCL/
    ├── COBOL/
    ├── REXX/
    └── ...
            │
            ▼
USERID.DEV.SRCLIB
USERID.JCL
USERID.REXX
...
```

This approach provides several advantages:

- Version-controlled starter content
- No dependency on an existing seed library
- Easier updates through Git
- Simpler onboarding for new environments
- Consistent provisioning across multiple systems

## Example Use Cases

- Developer onboarding
- IBM z/OS training environments
- Classroom labs
- Infrastructure as Code for IBM Z
- Repeatable provisioning of development environments
