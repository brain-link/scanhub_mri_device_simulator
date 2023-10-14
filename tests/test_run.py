# Copyright (C) 2023, BRAIN-LINK UG (haftungsbeschränkt). All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0-only OR LicenseRef-ScanHub-Commercial

import json

import requests


def start_scan():
    url = "http://localhost:5000/api/start-scan"
    # Get the record id from the user
    record_id = input("Enter the record id: ")
    # Generate test sequence
    sequence_json = '{ "name":"test_sequence", "version":1 }'
    # Send the request to the server
    response = requests.post(
        url,
        json={"record_id": record_id, "sequence": json.dumps(sequence_json)},
        timeout=60,
    )
    if response.status_code == 200:
        print("Simulation started successfully.")
    else:
        print("Failed to start simulation.")


# Call the start_scan function
start_scan()
