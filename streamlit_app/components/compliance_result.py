import streamlit as st

def render_compliance_result():
    st.subheader("📊 Compliance Result")

    if "result" not in st.session_state or not st.session_state["result"]:
        st.info("Run a compliance check to see results.")
        return

    result = st.session_state["result"]
    st.json(result)
