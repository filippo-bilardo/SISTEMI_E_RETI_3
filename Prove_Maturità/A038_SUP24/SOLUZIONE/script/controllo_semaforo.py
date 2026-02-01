#!/usr/bin/env python3
import os
import sys
import requests


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Uso: {sys.argv[0]} <base_url>", file=sys.stderr)
        return 2

    base_url = sys.argv[1].rstrip("/")
    token = os.getenv("TOKEN")

    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    status = requests.get(f"{base_url}/api/v1/status", headers=headers, timeout=5)
    status.raise_for_status()
    current = status.json()
    print("Stato attuale:", current)

    cmd = {
        "cmdId": "CMD-demo-0002",
        "action": "set_state",
        "params": {"state": "red", "durationSec": 300},
        "operatorId": "OP-042",
        "reason": "Sovraffollamento zona A"
    }

    resp = requests.post(f"{base_url}/api/v1/commands", json=cmd, headers=headers, timeout=5)
    resp.raise_for_status()
    print("Risposta comando:", resp.json())

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
