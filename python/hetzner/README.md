Hetzner Cloud CLI

A simple Python CLI for managing Hetzner Cloud servers.

Features

* Create servers
* List servers
* Delete servers
* Automatically uses all SSH keys configured in your Hetzner Cloud project
* Uses the Hetzner Cloud API via the official Python SDK

⸻

Prerequisites

* Python 3.9+
* Hetzner Cloud account
* Hetzner Cloud API token
* At least one SSH key configured in your Hetzner Cloud project

Installation

Create a virtual environment:

python3 -m venv venv
source venv/bin/activate

Install dependencies:

pip install hcloud

Configure API Token

Create an API token in the Hetzner Cloud Console:

1. Open your project
2. Navigate to Security
3. Select API Tokens
4. Create a new token

Export the token:

export HCLOUD_TOKEN="your-api-token"

To make this permanent, add it to your shell profile:

echo 'export HCLOUD_TOKEN="your-api-token"' >> ~/.profile

⸻

Usage

Using the hetzner shell script
./hetzner create my-server
./hetzner list
./hetzner delete --name my-server

Display help:

python hetzner.py --help

Create a Server

Create a server using the default settings:

python hetzner.py create my-server

Default configuration:

Setting	Value
Server Type	cx23
Image	ubuntu-24.04
Location	fsn1

Example output:

Created: my-server
ID: 12345678
IPv4: 203.0.113.10

Create a Server with Custom Options

Specify a different image:

python hetzner.py create my-server \
  --image debian-13

Specify a different location:

python hetzner.py create my-server \
  --location nbg1

Specify a different server type:

python hetzner.py create my-server \
  --type cpx11

Example:

python hetzner.py create web01 \
  --type cpx11 \
  --image ubuntu-24.04 \
  --location hel1

⸻

List Servers

Display all servers in your project:

python hetzner.py list

Example output:

ID         NAME                      TYPE       STATUS     IP
--------------------------------------------------------------------------------
12345678   web01                     cx23       running    203.0.113.10
12345679   test01                    cpx11      running    203.0.113.11

⸻

Delete a Server

Delete by name:

python hetzner.py delete --name web01

Delete by ID:

python hetzner.py delete --id 12345678

You will be prompted for confirmation:

Delete server 'web01' (ID=12345678)? [y/N]:

Skip confirmation:

python hetzner.py delete --id 12345678 --force

or

python hetzner.py delete --name web01 --force

⸻

SSH Access

The script automatically assigns all SSH keys configured in your Hetzner Cloud project.

After server creation:

ssh -i ~/.ssh/hetzner root@<server-ip>

Example:

ssh -i ~/.ssh/hetzner root@203.0.113.10

No password is required if your local private key matches one of the public keys uploaded to Hetzner Cloud.

⸻

Available Locations

Common Hetzner locations:

Location	Region
fsn1	Falkenstein, Germany
nbg1	Nuremberg, Germany
hel1	Helsinki, Finland
ash	Ashburn, USA
hil	Hillsboro, USA
sin	Singapore

⸻

Available Server Types

Examples:

Type	Description
cx23	Small x86 server
cpx11	Shared AMD CPU
cpx21	Larger shared AMD CPU
cax11	ARM-based instance

⸻

Troubleshooting

HCLOUD_TOKEN environment variable not set

Ensure your API token is exported:

export HCLOUD_TOKEN="your-api-token"

Server not found

Verify the server name or ID:

python hetzner.py list

Permission denied when connecting via SSH

Verify:

* Your SSH public key is uploaded to Hetzner Cloud
* The corresponding private key exists on your machine
* The server was created using that SSH key
