import streamlit as st
import tempfile
import os

def render_document_viewer():
    st.subheader("📄 Document Input")

    uploaded = st.file_uploader("Upload PDF or DOCX (or enter text below)", type=["pdf", "docx"])
    if uploaded is not None:
        # store uploaded file in session and return path to temp file
        tfile = tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(uploaded.name)[1])
        tfile.write(uploaded.getbuffer())
        tfile.flush()
        tfile.close()
        st.session_state["uploaded_file_path"] = tfile.name
        st.success(f"Uploaded: {uploaded.name}")
        return None

    # if no file, show text area
    return st.text_area("Enter text here", height=400, key="document_text")
