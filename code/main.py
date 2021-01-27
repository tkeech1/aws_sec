from typing import Optional

from fastapi import FastAPI, WebSocket
from pydantic import BaseModel

from datetime import datetime
import asyncio

app = FastAPI()


class Item(BaseModel):
    name: str
    price: float
    is_offer: Optional[bool] = None


class StreamlitData(BaseModel):
    streamlit_says: Optional[str] = None


@app.get("/")
async def read_root():
    return {"Hello": "From FastAPI"}


@app.post("/streamlit")
async def streamlit_endpoint(streamlit_data: StreamlitData):
    return {"fastapi_says": streamlit_data.streamlit_says}


@app.get("/items/{item_id}")
async def read_item(item_id: str, q: Optional[str] = None):
    return {"item_id": item_id, "q": q}


@app.put("/items/{item_id}")
async def update_item(item_id: int, item: Item):
    return {"item_name": item.name, "item_id": item_id}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    i = 1
    while True:
        await asyncio.sleep(1)
        # data = await websocket.receive_text()
        # await websocket.send_text(f"Message text was: {data}")
        await websocket.send_text(f"Websocket Message: {str(i)}")
        i = i + 1
