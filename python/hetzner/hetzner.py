#!/usr/bin/env python3

import argparse
import os
import sys

from hcloud import Client
from hcloud.images import Image
from hcloud.locations import Location
from hcloud.server_types import ServerType


def get_client():
    token = os.environ.get("HCLOUD_TOKEN")
    if not token:
        print("ERROR: HCLOUD_TOKEN environment variable not set")
        sys.exit(1)

    return Client(token=token)


def create_server(args):
    client = get_client()

    ssh_keys = client.ssh_keys.get_all()

    response = client.servers.create(
        name=args.name,
        server_type=ServerType(name=args.type),
        image=Image(name=args.image),
        location=Location(name=args.location),
        ssh_keys=ssh_keys,
        start_after_create=True,
    )

    server = response.server

    print(f"Created: {server.name}")
    print(f"ID: {server.id}")

    if server.public_net.ipv4:
        print(f"IPv4: {server.public_net.ipv4.ip}")


def list_servers(args):
    client = get_client()

    servers = client.servers.get_all()

    if not servers:
        print("No servers found")
        return

    print(
        f"{'ID':<10} {'NAME':<25} {'TYPE':<10} {'STATUS':<10} {'IP'}"
    )
    print("-" * 80)

    for server in servers:
        ip = (
            server.public_net.ipv4.ip
            if server.public_net.ipv4
            else "-"
        )

        print(
            f"{server.id:<10} "
            f"{server.name:<25} "
            f"{server.server_type.name:<10} "
            f"{server.status:<10} "
            f"{ip}"
        )


def delete_server(args):
    client = get_client()

    server = None

    if args.id:
        server = client.servers.get_by_id(args.id)
    else:
        server = client.servers.get_by_name(args.name)

    if not server:
        print("Server not found")
        sys.exit(1)

    if not args.force:
        confirm = input(
            f"Delete server '{server.name}' (ID={server.id})? [y/N]: "
        )

        if confirm.lower() != "y":
            print("Cancelled")
            return

    server.delete()
    print(f"Deleted server '{server.name}'")


def main():
    parser = argparse.ArgumentParser(
        description="Hetzner Cloud CLI"
    )

    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True

    # create
    create = subparsers.add_parser(
        "create",
        help="Create a server",
    )

    create.add_argument(
        "name",
        help="Server name",
    )

    create.add_argument(
        "--type",
        default="cx23",
        help="Server type (default: cx23)",
    )

    create.add_argument(
        "--image",
        default="ubuntu-24.04",
        help="Image (default: ubuntu-24.04)",
    )

    create.add_argument(
        "--location",
        default="fsn1",
        help="Location (default: fsn1)",
    )

    create.set_defaults(func=create_server)

    # list
    ls = subparsers.add_parser(
        "list",
        help="List servers",
    )

    ls.set_defaults(func=list_servers)

    # delete
    delete = subparsers.add_parser(
        "delete",
        help="Delete a server",
    )

    group = delete.add_mutually_exclusive_group(required=True)

    group.add_argument(
        "--id",
        type=int,
        help="Server ID",
    )

    group.add_argument(
        "--name",
        help="Server name",
    )

    delete.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Do not prompt",
    )

    delete.set_defaults(func=delete_server)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
