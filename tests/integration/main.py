import json
import time

import boto3
from jsonschema import Draft7Validator

OUTER_SCHEMA_PATH = "tests/json_schemas/outer.json"


def main():
    with open(OUTER_SCHEMA_PATH, encoding="utf-8") as schema_file:
        outer_schema = json.load(schema_file)
    validator = Draft7Validator(outer_schema)

    kinesis = boto3.client(
        "kinesis",
        endpoint_url="http://localhost:4566",
        region_name="us-east-1",
        aws_access_key_id="test",
        aws_secret_access_key="test",
    )

    print("Connecting to Kinesis stream main-stream...", flush=True)
    stream = kinesis.describe_stream(StreamName="main-stream")
    shard_id = stream["StreamDescription"]["Shards"][0]["ShardId"]
    iterator = kinesis.get_shard_iterator(
        StreamName="main-stream",
        ShardId=shard_id,
        ShardIteratorType="LATEST",
    )["ShardIterator"]

    attempts = 0
    while attempts < 30:
        print(f"Attempt {attempts + 1}/30: polling for records", flush=True)
        response = kinesis.get_records(ShardIterator=iterator, Limit=1)
        iterator = response["NextShardIterator"]
        records = response.get("Records", [])

        if records:
            record = records[0]
            raw_data = record["Data"].decode("utf-8")
            event_payload = json.loads(raw_data)
            outer_event = event_payload.get("detail", event_payload)
            validator.validate(outer_event)
            print("Validated event:", outer_event, flush=True)
            return

        attempts += 1
        time.sleep(5)

    raise SystemExit("Integration test failed: no records observed in main-stream")


if __name__ == "__main__":
    main()
