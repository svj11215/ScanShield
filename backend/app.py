from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import os

from analyzer.apk_analyzer import analyze_apk
from analyzer.pdf_analyzer import analyze_pdf
from analyzer.risk_engine import calculate_risk

# Configure logging for tracking request lifecycles and cold starts
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger("scanshield_api")

app = Flask(__name__)
CORS(app)

app.config["MAX_CONTENT_LENGTH"] = 100 * 1024 * 1024

UPLOAD_FOLDER = "uploads"
REPORTS_FOLDER = "reports"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(REPORTS_FOLDER, exist_ok=True)


@app.errorhandler(413)
def request_entity_too_large(error):
    logger.warning("File rejected: Exceeds maximum 100 MB content length limit.")
    return jsonify({"error": "File too large (Maximum 100 MB)"}), 413


@app.errorhandler(404)
def page_not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_server_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({"error": "Internal server error"}), 500


@app.route("/")
def home():
    logger.info("Health check / warm-up ping received.")
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
    logger.info("Received POST /analyze request.")
    if "file" not in request.files:
        logger.warning("Request rejected: missing 'file' field.")
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]

    if file.filename == "":
        logger.warning("Request rejected: empty filename.")
        return jsonify({"error": "Empty filename"}), 400

    filename_lower = file.filename.lower()
    if not (filename_lower.endswith(".apk") or filename_lower.endswith(".pdf")):
        logger.warning(f"Request rejected: unsupported extension for '{file.filename}'.")
        return jsonify({"error": "Unsupported extension. Only .apk and .pdf are supported."}), 400

    filepath = os.path.join(UPLOAD_FOLDER, file.filename)

    try:
        file.save(filepath)
        file_size_mb = os.path.getsize(filepath) / (1024 * 1024)
        logger.info(f"File saved to buffer: '{file.filename}' ({file_size_mb:.2f} MB)")

        if filename_lower.endswith(".apk"):
            logger.info(f"Executing APK static analysis for '{file.filename}'...")
            result = analyze_apk(filepath)
        else:
            logger.info(f"Executing PDF analysis for '{file.filename}'...")
            result = analyze_pdf(filepath)

        risk_data = calculate_risk(result)
        result.update(risk_data)
        logger.info(f"Analysis completed successfully for '{file.filename}'. Risk Level: {result.get('risk_level')}, Score: {result.get('overall_risk')}")
        return jsonify(result)

    except Exception as e:
        logger.error(f"Analysis exception on '{file.filename}': {e}", exc_info=True)
        return jsonify({"error": f"Analysis failed: {str(e)}"}), 500

    finally:
        if os.path.exists(filepath):
            os.remove(filepath)
            logger.info(f"Cleaned up temporary buffer file: '{filepath}'")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)