import streamlit as st

def init_state():
    if "result" not in st.session_state:
        st.session_state["result"] = None
