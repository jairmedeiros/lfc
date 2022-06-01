# Liferay-tool

Liferay tool is a tool to manage local environment in some tasks, such as cleaning database, cleaning git cache, tomcat folders and docker db

## Installation

Clone this repo in some folder of your choice, and then create an alias to ge.sh in your ~/.bashrc

### Example

alias lfc="sh ~/dev/projects/lfc/ge.sh"

## Usage

```bash
#this command perform all the cleanings and erase the database
lfc --all

```

## <span style="color: red; font-weight:bold;">!Important</span>
This tool will only work on liferay environment and liferay's workstations
