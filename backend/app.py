from flask import Flask, request, jsonify
from flask_cors import CORS

from analyzer.apk_analyzer import analyze_apk
from analyzer.pdf_analyzer import analyze_pdf
from analyzer.risk_engine import calculate_risk

import os

app = Flask(__name__)
CORS(app)

app.config["MAX_CONTENT_LENGTH"] = 100 * 1024 * 1024

UPLOAD_FOLDER = "uploads"
REPORTS_FOLDER = "reports"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(REPORTS_FOLDER, exist_ok=True)


@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({"error": "File too large (Maximum 100 MB)"}), 413


@app.errorhandler(404)
def page_not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_server_error(error):
    return jsonify({"error": "Internal server error"}), 500


@app.route("/")
def home():
    return jsonify({
        "message": "ScanShield Backend Running",
        "status": "success",
        "version": "1.0.0",
        "service": "ScanShield API",
        "endpoints": [
            "/",
            "/analyze"
        ]
    })


@app.route("/analyze", methods=["POST"])
def analyze():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "Empty filename"}), 400

    filename_lower = file.filename.lower()
    if not (filename_lower.endswith(".apk") or filename_lower.endswith(".pdf")):
        return jsonify({"error": "Unsupported extension"}), 400

    filepath = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(filepath)

    try:
        if filename_lower.endswith(".apk"):
            result = analyze_apk(filepath)
        else:
            result = analyze_pdf(filepath)

        result.update(calculate_risk(result))
        return jsonify(result)

    finally:
        if os.path.exists(filepath):
            os.remove(filepath)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)