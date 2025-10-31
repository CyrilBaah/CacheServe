from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Any, Dict
import uvicorn

app = FastAPI(title="CacheServe", description="Minimal in-memory caching microservice")

# In-memory cache
cache: Dict[str, Any] = {}

class CacheItem(BaseModel):
    value: Any

@app.get("/")
def root():
    return {"message": "CacheServe - In-memory caching microservice"}

@app.get("/cache/{key}")
def get_cache(key: str):
    if key not in cache:
        raise HTTPException(status_code=404, detail="Key not found")
    return {"key": key, "value": cache[key]}

@app.post("/cache/{key}")
def set_cache(key: str, item: CacheItem):
    cache[key] = item.value
    return {"key": key, "value": item.value, "status": "cached"}

@app.put("/cache/{key}")
def update_cache(key: str, item: CacheItem):
    if key not in cache:
        raise HTTPException(status_code=404, detail="Key not found")
    cache[key] = item.value
    return {"key": key, "value": item.value, "status": "updated"}

@app.delete("/cache/{key}")
def delete_cache(key: str):
    if key not in cache:
        raise HTTPException(status_code=404, detail="Key not found")
    del cache[key]
    return {"key": key, "status": "deleted"}

@app.get("/cache")
def list_cache():
    return {"cache": cache, "count": len(cache)}

@app.delete("/cache")
def clear_cache():
    cache.clear()
    return {"status": "cache cleared"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
