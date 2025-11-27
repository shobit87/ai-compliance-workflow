import streamlit as st

def render_sidebar():
    st.sidebar.title("⚙️ Options")
    st.sidebar.text_input("Forbidden Keywords (comma separated)", key="keywords")
