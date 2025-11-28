import json

import streamlit as st
import requests
import plotly.graph_objects as go

# ---------------- PAGE CONFIG ----------------
st.set_page_config(page_title="dY AI Compliance Checker", layout="wide")

# ---------------- GLOBAL STYLES ----------------
st.markdown(
    """
<style>
:root {
    --bg: #f4f6fb;
    --text: #0f172a;
    --card-bg: #ffffff;
    --border: #e2e8f0;
    --accent: #305adf;
    --ok: #16a34a;
    --warn: #f59e0b;
    --bad: #dc2626;
}
html, body, .stApp {
    background-color: var(--bg);
    color: var(--text);
    font-family: "Inter", sans-serif;
}
.stSidebar {
    background: var(--card-bg);
}
.hero-card {
    padding: 26px;
    border-radius: 20px;
    border: 1px solid rgba(255,255,255,0.2);
    background: radial-gradient(circle at top, #14234b, #0b1324);
    color: #f8fafc;
    box-shadow: 0 25px 50px rgba(15, 23, 42, 0.55);
    margin-bottom: 30px;
}
.hero-card h1 {
    margin-bottom: 8px;
}
.hero-card p {
    font-size: 16px;
    margin: 0;
    opacity: 0.8;
}
.metric-card {
    background: var(--card-bg);
    padding: 18px;
    border-radius: 16px;
    border: 1px solid var(--border);
    box-shadow: 0 10px 25px rgba(15, 23, 42, 0.08);
    height: 100%;
}
.metric-card h4 {
    font-size: 13px;
    letter-spacing: 0.08em;
    color: #94a3b8;
    margin-bottom: 6px;
    text-transform: uppercase;
}
.metric-card .value {
    font-size: 30px;
    font-weight: 700;
}
.result-card {
    background: var(--card-bg);
    padding: 26px;
    border-radius: 20px;
    border: 1px solid var(--border);
    box-shadow: 0 30px 60px rgba(15, 23, 42, 0.12);
    margin-bottom: 30px;
}
.result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}
.result-header h3 {
    margin: 0;
}
.muted {
    color: #8693a6;
    font-size: 14px;
}
.status-chip {
    padding: 6px 18px;
    border-radius: 999px;
    font-size: 13px;
    font-weight: 600;
    border: 1px solid var(--border);
}
.status-chip.ok {color: var(--ok); background: #ecfdf3;}
.status-chip.warn {color: var(--warn); background: #fff7eb;}
.status-chip.bad {color: var(--bad); background: #fee2e2;}
.recommendation-item {
    border-left: 4px solid var(--accent);
    background: #eef2ff;
    padding: 12px 16px;
    border-radius: 10px;
    margin-bottom: 10px;
}
.summary-card {
    background: linear-gradient(145deg, #ffffff 0%, #f5f7ff 100%);
    padding: 18px;
    border-radius: 16px;
    border: 1px solid var(--border);
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.6);
    min-height: 140px;
}
</style>
""",
    unsafe_allow_html=True,
)

# ---------------- HERO HEADER ----------------
st.markdown(
    """
<div class="hero-card">
    <h1>dY AI Compliance Checker</h1>
    <p>Upload policy drafts or contracts to receive automated compliance scoring,
    summarized findings, and prioritized recommendations in a single executive view.</p>
</div>
""",
    unsafe_allow_html=True,
)

# ---------------- SIDEBAR CONFIG ----------------
st.sidebar.title("Configuration")
st.sidebar.write(
    "Tune the automated checks before running an analysis. Settings are applied to all uploads."
)
rules_input = st.sidebar.text_input("Forbidden Keywords (comma separated)")
sector = st.sidebar.selectbox(
    "Business Sector", ["General", "Finance", "Healthcare", "IT", "Legal"]
)
forbidden_keywords = [x.strip() for x in rules_input.split(",") if x.strip()]

# ---------------- LAYOUT ----------------
left, right = st.columns([1.05, 2.25])

with left:
    st.subheader("Upload Documents")
    st.caption("Securely upload PDF or DOCX files for review.")
    uploaded_files = st.file_uploader(
        "Upload files", type=["pdf", "docx"], accept_multiple_files=True
    )
    run = st.button(
        "Run Compliance Check",
        use_container_width=True,
        disabled=not uploaded_files,
    )
    if not uploaded_files:
        st.info("Select one or more files to enable the workflow.")

reports = []
session = requests.Session()


@st.cache_data(show_spinner=False, ttl=600)
def analyze_document(file_bytes: bytes, filename: str, keywords: tuple[str, ...], sector: str):
    keyword_payload = ",".join(keywords)
    response = session.post(
        "http://127.0.0.1:8000/api/v1/compliance/check-file",
        files={"file": (filename, file_bytes)},
        data={"forbidden_keywords": keyword_payload, "sector": sector},
    )
    return response.status_code, response.text

# ---------------- PROCESS FILES ----------------
if uploaded_files and run:
    keywords_tuple = tuple(forbidden_keywords)
    for file in uploaded_files:
        with st.spinner(f"Analyzing {file.name}..."):
            try:
                file_bytes = file.getvalue()
                status, payload = analyze_document(file_bytes, file.name, keywords_tuple, sector)
                if status == 200:
                    reports.append((file.name, json.loads(payload)))
                else:
                    st.error(f"{file.name}: API error ({status}) - {payload}")
            except Exception as exc:
                st.error(f"{file.name}: Connection failed - {exc}")

# ---------------- RESULTS ----------------
with right:
    st.subheader("Analysis Workspace")
    st.caption("Insights refresh automatically for every uploaded document.")

    if run and not reports:
        st.warning(
            "No reports were generated. Confirm that the backend service is running and reachable."
        )

    for idx, (name, data) in enumerate(reports):
        score = data.get("score", 0)
        status = "Compliant" if score >= 80 else "Review" if score >= 50 else "High Risk"
        sentiment = data.get("sentiment", {}).get("sentiment", "N/A")
        findings = data.get("findings", [])
        tokens = data.get("tokens", {})
        risk = data.get("risk_level", "LOW")
        badge = "ok" if score >= 80 else "warn" if score >= 50 else "bad"

        with st.container():
            st.markdown(
                f"""
                <div class="result-card">
                    <div class="result-header">
                        <div>
                            <h3>{name}</h3>
                            <p class="muted">Sector: {sector}</p>
                        </div>
                        <span class="status-chip {badge}">{status}</span>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )

            metric_cols = st.columns(4, gap="medium")
            metric_cols[0].markdown(
                f"<div class='metric-card'><h4>Score</h4><div class='value'>{score}%</div></div>",
                unsafe_allow_html=True,
            )
            metric_cols[1].markdown(
                f"<div class='metric-card'><h4>Sentiment</h4><div class='value'>{sentiment}</div></div>",
                unsafe_allow_html=True,
            )
            metric_cols[2].markdown(
                f"<div class='metric-card'><h4>Risk Level</h4><div class='value'>{risk}</div></div>",
                unsafe_allow_html=True,
            )
            metric_cols[3].markdown(
                f"<div class='metric-card'><h4>Findings</h4><div class='value'>{len(findings)}</div></div>",
                unsafe_allow_html=True,
            )

            summary_tab, findings_tab, recs_tab, metrics_tab = st.tabs(
                ["Executive Summary", "Findings", "Recommendations", "LLM Metrics"]
            )

            with summary_tab:
                st.markdown(
                    f"<div class='summary-card'>{data.get('summary', 'Summary unavailable.')}</div>",
                    unsafe_allow_html=True,
                )

            with findings_tab:
                if findings:
                    st.dataframe(findings, use_container_width=True)
                else:
                    st.success("No policy violations detected in this document.")

            with recs_tab:
                recommendations = [
                    entry.strip()
                    for entry in data.get("recommendations", "").split("\n")
                    if entry.strip()
                ]
                if recommendations:
                    for rec in recommendations:
                        st.markdown(
                            f"<div class='recommendation-item'>{rec}</div>",
                            unsafe_allow_html=True,
                        )
                else:
                    st.info("No automated recommendations generated.")

            with metrics_tab:
                token_cols = st.columns(2, gap="large")
                with token_cols[0]:
                    if tokens:
                        fig = go.Figure(
                            go.Bar(
                                x=["Input", "Output"],
                                y=[tokens.get("input", 0), tokens.get("output", 0)],
                                marker_color=["#3b82f6", "#22c55e"],
                            )
                        )
                        fig.update_layout(
                            height=320,
                            template="plotly_white",
                            margin=dict(l=10, r=10, t=40, b=10),
                            title="LLM Token Usage",
                        )
                        st.plotly_chart(
                            fig,
                            width="stretch",
                            key=f"plotly_tokens_{idx}_{name}",
                        )
                    else:
                        st.info("Token usage data not available.")
                with token_cols[1]:
                    st.write("Risk Meter")
                    gauge_value = 90 if risk == "LOW" else 60 if risk == "MEDIUM" else 30
                    g = go.Figure(
                        go.Indicator(
                            mode="gauge+number",
                            value=gauge_value,
                            gauge={"axis": {"range": [0, 100]}},
                        )
                    )
                    g.update_layout(
                        height=320,
                        margin=dict(l=10, r=10, t=40, b=10),
                    )
                    st.plotly_chart(
                        g,
                        width="content",
                        key=f"plotly_risk_{idx}_{name}",
                    )
