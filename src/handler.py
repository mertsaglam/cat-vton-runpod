import runpod
import os
import base64
import time
import json
import requests
import string
import random
import io
from PIL import Image

def save_image(base64_string, save_name):
    image_data = base64.b64decode(base64_string)
    image = Image.open(io.BytesIO(image_data))
    save_path = f"input/{save_name}"
    image.save(save_path)
    print(f"runpod-worker-comfy - Saved base64 image to {save_path}")
    
def convert_image_to_base64(image_path):
    with open(image_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read())
    return encoded_string.decode('utf-8')

def generate_random_seed():
    return random.randint(10**15, 10**16 - 1)

def check_server(url, retries=50, delay=500):
    for i in range(retries):
        try:
            response = requests.get(url)

            if response.status_code == 200:
                print(f"runpod-worker-comfy - API is reachable")
                return True
        except requests.RequestException as e:
            pass

        time.sleep(delay / 1000)

    print(
        f"runpod-worker-comfy - Failed to connect to server at {url} after {retries} attempts."
    )
    return False

def poll_result(url, prompt_id):
    completed = False
    history = {}

    while not completed:
        time.sleep(1)
        response = requests.request("GET",f"{url}/history")
        history = response.json()
        completed = prompt_id in history
    result_image_name = history[prompt_id]["outputs"]["21"]["images"][0]["filename"]

    return result_image_name

def handler(job):
    try:
        # Ensure required params
        required_params = ["human_image_b64", "garment_image_b64", "sam_prompt", "sam_threshold", "mask_grow", "mixed_precision", "seed", "steps", "cfg"]
        for param in required_params:
            if param not in job['input']:
                return {"status": 400, "message": f"Missing required parameter '{param}'"}
    
        # Get params
        human_image_b64 = job['input']["human_image_b64"]
        garment_image_b64 = job['input']["garment_image_b64"]
        sam_prompt = job['input']["sam_prompt"]
        sam_threshold = float(job['input']["sam_threshold"])
        mask_grow = int(job['input']["mask_grow"])
        mixed_precision = job['input']["mixed_precision"]
        seed = int(job['input']["seed"])
        steps = int(job['input']["steps"])
        cfg = float(job['input']["cfg"])

        # Save b64 images 
        human_image_name = f"human_{generate_random_seed()}.png" 
        garment_image_name = f"garment_{generate_random_seed()}.png" 
        save_image(human_image_b64, human_image_name)
        save_image(garment_image_b64, garment_image_name)

        with open('human_garment_workflow_api.json', 'r') as file:
            workflow = json.load(file)
            
        # Set workflow values
        workflow["3"]["inputs"]["image"] = human_image_name
        workflow["4"]["inputs"]["image"] = garment_image_name
        
        workflow["10"]["inputs"]["prompt"] = sam_prompt
        workflow["10"]["inputs"]["threshold"] = sam_threshold
        
        workflow["2"]["inputs"]["mask_grow"] = mask_grow
        workflow["2"]["inputs"]["mixed_precision"] = mixed_precision
        workflow["2"]["inputs"]["seed"] = seed
        workflow["2"]["inputs"]["steps"] = steps
        workflow["2"]["inputs"]["cfg"] = cfg
        
        url = "http://127.0.0.1:8188"
        check_server(url)

        # create prompt
        p = {"prompt": workflow}
        data = json.dumps(p).encode('utf-8')
        headers = { 'Content-Type': 'application/json'}
        response =  requests.request("POST",f"{url}/prompt", data=data,headers=headers)
        prompt_id = response.json()["prompt_id"]

        result_image_name = poll_result(url, prompt_id)
        
        return {"status": 200, "message": "Image created successfully", "payload": {"result":convert_image_to_base64(f"output/{result_image_name}")}}

    except Exception as e:
        return {"status": 500, "message": str(e)}

runpod.serverless.start({"handler": handler})