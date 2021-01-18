import streamlit as st

import numpy as np
import pandas as pd
import httpx
from datetime import datetime
import asyncio
import websockets
from websockets import ConnectionClosedOK

st.set_page_config(layout="wide")

# hack to hide hamburger menu and footer
# https://github.com/streamlit/streamlit/issues/395
hide_menu_style = """
        <style>
        #MainMenu {visibility: hidden;}
        footer {visibility: hidden;}
        </style>
        """
st.markdown(hide_menu_style, unsafe_allow_html=True)
# end hack to hide hamburger menu

st.title("Hello")
st.subheader("Get")


async def get():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://127.0.0.1:8000/")
    return st.subheader(r.json())


asyncio.run(get())


async def request(value):
    async with httpx.AsyncClient() as client:
        res = await client.post(
            "http://127.0.0.1:8000/streamlit", json={"streamlit_says": value}
        )
    st.subheader(res.json())


async def ws(test):
    uri = "ws://localhost:8000/ws"
    async with websockets.connect(uri) as websocket:
        # name = input("What's your name? ")
        # await websocket.send(name)
        # print(f"> {name}")
        while True:
            try:
                greeting = await websocket.recv()
                test.markdown(f"{greeting}")
            except websockets.ConnectionClosedOK:
                break


test = st.empty()

st.subheader("Post")
myvalue = st.text_input("Streamlit says...", "streamlit says hi")
submit = st.button("submit to fastapi")
if submit:
    asyncio.run(request(myvalue))
    asyncio.run(ws(test))

# asyncio.run(ws(test))
# asyncio.get_event_loop().run_until_complete(hello(test))
