import json
import re
from io import BytesIO

import requests
import streamlit as st
from fpdf import FPDF

API_URL = "http://localhost:8000/api/v1/compliance/check-file"

# -----------------------------
# PAGE CONFIG + DARK THEME
# -----------------------------
st.set_page_config(
    page_title="AI Compliance Engine",
    page_icon="✅",
    layout="wide",
)

# Custom dark-ish styling
st.markdown(
    """
<style>
body {
    background-color: #0f172a;
}
[data-testid="stAppViewContainer"] {
    background-color: #020617;
    color: #e5e7eb;
}
[data-testid="stSidebar"] {
    background-color: #020617;
}
.card {
    background-color: #020617;
    padding: 16px;
    border-radius: 12px;
    border: 1px solid #1f2937;
}
.metric {
    font-size:20px; font-weight:bold;
}
.badge-ok {
    background:#022c22;
    color:#6ee7b7;
    padding:6px 12px;
    border-radius:999px;
    display:inline-block;
}
.badge-warn {
    background:#3f1d1d;
    color:#fecaca;
    padding:6px 12px;
    border-radius:999px;
    display:inline-block;
}
.badge-neutral {
    background:#111827;
    color:#e5e7eb;
    padding:6px 12px;
    border-radius:999px;
    display:inline-block;
}
.highlight-text {
    background-color: #111827;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #1f2937;
    white-space: pre-wrap;
    font-family: "SF Mono","Consolas","Menlo",monospace;
    font-size: 13px;
}
mark {
    background-color: #f97316;
    color: #020617;
}
</style>
""",
    unsafe_allow_html=True,
)

# -----------------------------
# SIDEBAR
# -----------------------------
with st.sidebar:
    st.title("⚙️ Options")
    forbidden = st.text_input("Forbidden Keywords (comma separated)", help="e.g. secret, leak, NDA")
    rules = {
        "forbidden_keywords": [x.strip() for x in forbidden.split(",") if x.strip()]
    }
    st.caption("These keywords will be flagged as compliance findings.")

# -----------------------------
# HEADER
# -----------------------------
st.title("📄 AI Compliance Checker")

left_col, right_col = st.columns([1.1, 1])

# -----------------------------
# FILE INPUT (MULTI-FILE)
# -----------------------------
with left_col:
    st.subheader("Document Input")
    uploaded_files = st.file_uploader(
        "Upload one or more PDF / DOCX files",
        type=["pdf", "docx"],
        accept_multiple_files=True,
    )
    run = st.button("Run Compliance Check")

# -----------------------------
# UTILITIES
# -----------------------------
def call_backend(file, rules: dict):
    files = {"file": (file.name, file, file.type)}
    payload = {"rules": json.dumps(rules)}

    res = requests.post(API_URL, data=payload, files=files)
    if res.status_code != 200:
        raise RuntimeError(f"Backend error: {res.status_code} {res.text}")
    return res.json()


def build_pdf_report(filename: str, data: dict) -> bytes:
    buffer = BytesIO()

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "AI Compliance Report", ln=True, align="C")

    pdf.ln(5)
    pdf.set_font("Arial", "", 11)
    pdf.cell(0, 8, f"File Name: {filename}", ln=True)
    pdf.cell(0, 8, f"Score: {data.get('score', 0)}/100", ln=True)

    pdf.ln(4)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Summary", ln=True)
    pdf.set_font("Arial", "", 11)
    pdf.multi_cell(0, 6, data.get("summary", "No summary generated"))

    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Sentiment", ln=True)
    pdf.set_font("Arial", "", 11)
    s = data.get("sentiment", {})
    pdf.multi_cell(0, 6, f"{s.get('sentiment')} (polarity={round(s.get('polarity', 0),2)})")

    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Findings", ln=True)
    pdf.set_font("Arial", "", 11)

    findings = data.get("findings", [])
    if not findings:
        pdf.multi_cell(0, 6, "No compliance issues detected.")
    else:
        for f in findings:
            pdf.multi_cell(0, 6, f"- {f.get('keyword')}: {f.get('message')}")

    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(0, 8, "Recommendations", ln=True)
    pdf.set_font("Arial", "", 11)
    pdf.multi_cell(0, 6, data.get("recommendations", "No recommendations"))
    
    # ✅ ONLY SAFE WAY
    raw = pdf.output(dest="S")
    pdf_bytes = bytes(raw) if isinstance(raw, (bytearray, bytes)) else raw.encode("latin-1")
    return pdf_bytes



def highlight_text(text: str, findings: list) -> str:
    """Highlight risky keywords in the original document text."""
    if not text:
        return "No text available from backend."

    keywords = {f.get("keyword", "").strip() for f in findings if f.get("keyword")}
    highlighted = text

    for kw in sorted(keywords, key=len, reverse=True):
        if not kw:
            continue
        pattern = re.compile(re.escape(kw), re.IGNORECASE)
        highlighted = pattern.sub(r"<mark>\g<0></mark>", highlighted)

    return highlighted


# -----------------------------
# MAIN RESULTS PANEL
# -----------------------------
with right_col:
    st.subheader("Compliance Result")
    results_area = st.container()

if run and uploaded_files:
    with results_area:
        for file in uploaded_files:
            st.markdown(f"## 📁 {file.name}")
            try:
                data = call_backend(file, rules)
            except Exception as e:
                st.error(f"Error processing {file.name}: {e}")
                continue

            # STATUS + SCORE
            status_ok = data.get("status") == "ok"
            score = data.get("score", 0)

            badge_class = "badge-ok" if status_ok else "badge-warn"
            status_label = "PASSED" if status_ok else "FAILED"

            st.markdown(
                f'<span class="{badge_class}">Status: {status_label} · Score: {score}/100</span>',
                unsafe_allow_html=True,
            )
            st.progress(score / 100)

            # LAYOUT for each file
            c1, c2 = st.columns([1.3, 1])

            # -------- LEFT: SUMMARY + RECS --------
            with c1:
                st.markdown("#### 📌 Summary")
                st.markdown('<div class="card">', unsafe_allow_html=True)
                for line in data.get("summary", "").split("\n"):
                    if line.strip():
                        st.markdown(f"- {line.strip('- ')}")
                st.markdown("</div>", unsafe_allow_html=True)

                st.markdown("#### ✅ Recommendations")
                st.markdown('<div class="card">', unsafe_allow_html=True)
                for line in data.get("recommendations", "").split("\n"):
                    if line.strip():
                        st.markdown(f"• {line.strip('- ')}")
                st.markdown("</div>", unsafe_allow_html=True)

            # -------- RIGHT: SENTIMENT + FINDINGS + HIGHLIGHT --------
            with c2:
                st.markdown("#### 😊 Sentiment")
                sent = data.get("sentiment", {"polarity": 0, "sentiment": "Neutral"})
                polarity = sent.get("polarity", 0)
                sentiment_label = sent.get("sentiment", "Neutral")

                if polarity < -0.3:
                    s_class = "badge-warn"
                elif polarity > 0.3:
                    s_class = "badge-ok"
                else:
                    s_class = "badge-neutral"

                st.markdown(
                    f'<span class="{s_class}">{sentiment_label} (polarity={round(polarity,2)})</span>',
                    unsafe_allow_html=True,
                )

                st.markdown("#### 🚨 Findings")
                findings = data.get("findings", [])
                if findings:
                    for f in findings:
                        kw = f.get("keyword", "")
                        msg = f.get("message", "")
                        st.warning(f"{kw}: {msg}")
                else:
                    st.success("No forbidden keywords or rule violations found.")

                st.markdown("#### 🔍 Highlighted Risky Text")
                original_text = data.get("text", "")
                highlighted = highlight_text(original_text, findings)
                st.markdown(
                    f'<div class="highlight-text">{highlighted}</div>',
                    unsafe_allow_html=True,
                )

            # -------- PDF DOWNLOAD --------
            pdf_bytes = build_pdf_report(file.name, data)
            st.download_button(
                label="📥 Download PDF Report",
                data=pdf_bytes,
                file_name="compliance_report.pdf",
                mime="application/pdf"
                )


            # -------- RAW JSON (optional) --------
            with st.expander("🔧 Raw JSON (debug)"):
                st.json(data)

            st.markdown("---")
