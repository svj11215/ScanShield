import fitz

def analyze_pdf(file_path):
    doc = fitz.open(file_path)

    return {
        "pages": len(doc),
        "is_encrypted": doc.is_encrypted,
        "metadata": doc.metadata
    }