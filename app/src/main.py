from flask import Flask, jsonify
import os
import time
import random

app = Flask(__name__)

VERSION = os.getenv("APP_VERSION", "v1")
MODE = os.getenv("APP_MODE", "stable")
FAULT_RATE = float(os.getenv("FAULT_RATE", "0.0"))
EXTRA_LATENCY = float(os.getenv("EXTRA_LATENCY", "0.0"))  # seconds


@app.route("/")
def root():
    if MODE == "faulty":
        if random.random() < FAULT_RATE:
            return jsonify(
                {
                    "version": VERSION,
                    "mode": MODE,
                    "status": "error",
                    "message": "Intentional failure for canary testing",
                }
            ), 500
        if EXTRA_LATENCY > 0:
            time.sleep(EXTRA_LATENCY)
    return jsonify(
        {
            "version": VERSION,
            "mode": MODE,
            "status": "ok",
            "message": "Hello from progressive delivery demo",
        }
    )


@app.route("/health")
def health():
    return "OK", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
