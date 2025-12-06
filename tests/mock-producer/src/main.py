import json
import os
import random
import time
from pathlib import Path

import boto3
from botocore.exceptions import EndpointConnectionError
from jsf import JSF


def main():
    eventbridge = boto3.client(
        "events",
        endpoint_url="http://localstack:4566",
        region_name="us-east-1",
        aws_access_key_id="test",
        aws_secret_access_key="test",
    )

    # Wait for EventBridge to be provisioned
    while True:
        try:
            eventbridge.describe_event_bus(Name="source-bus")
            print(f"EventBridge is provisioned.", flush=True)
            break
        except Exception as e:
            print(f"EventBridge not provisioned yet: {e}", flush=True)
            time.sleep(1)

    # Outer JSON Schema
    outer_schema = Path("/json_schemas/outer.json")

    # Inner JSON Schemas
    inner_schemas = []
    for schema_name in os.listdir("/json_schemas"):
        if schema_name == outer_schema.name:
            continue
        inner_schemas.append(str(Path("/json_schemas") / schema_name))

    # Iterate randomly over the list of schemas, and send events
    while True:
        selected_inner = random.choice(inner_schemas)
        selected_inner_name = os.path.splitext(os.path.basename(selected_inner))[0]
        mocked_inner = JSF.from_json(selected_inner).generate()
        mocked_outer = JSF.from_json(outer_schema).generate()
        mocked_outer["event_type"] = selected_inner_name
        mocked_outer["message"] = json.dumps(mocked_inner, separators=(",", ":"))
        complete_event = json.dumps(mocked_outer, separators=(",", ":"))

        try:
            eventbridge.put_events(
                Entries=[
                    {
                        "Source": "mock-producer",
                        "DetailType": selected_inner_name,
                        "Detail": complete_event,
                        "EventBusName": "source-bus",
                    }
                ]
            )
        except Exception as e:
            time.sleep(1)
            continue

        print(f"Sent event {complete_event}", flush=True)
        time.sleep(10)

if __name__ == "__main__":
    main()
